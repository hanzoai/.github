#!/usr/bin/env bash
# forge-migrate.sh — move a repo estate onto git.hanzo.ai as CANONICAL.
#
# git.hanzo.ai is canonical; GitHub is a mirror. CI/CD and PaaS are native
# (platform.hanzo.ai builds, cd.hanzo.ai delivers). This script performs the
# THREE ordered steps that get an estate there, and refuses to run a step
# whose precondition is not met. Order is not optional:
#
#   1. status    — report, change nothing. Always safe. Start here.
#   2. provision — create the missing PULL MIRRORS on git.hanzo.ai.
#                  Until a repo exists on the forge, mirror-sync 404s and a
#                  mirror workflow correctly fails. This is the real blocker.
#   3. convert   — reverse ONE repo: pull mirror -> canonical. Required.
#                  A pull mirror is NOT canonical: the forge runs
#                  `git remote update --prune` against GitHub on a timer,
#                  so anything pushed straight to it is pruned minutes
#                  later, silently. `repoint` REFUSES un-converted repos.
#   4. repoint   — flip local `origin` to git.hanzo.ai and demote GitHub to
#                  the `mirror` remote. Gated on the forge repo existing,
#                  being non-empty, AND no longer being a mirror.
#
# Read-only by default. Every mutating step requires --apply.
#
#   ./forge-migrate.sh status
#   ./forge-migrate.sh provision --org lux --apply
#   ./forge-migrate.sh convert  --repo luxfi/consensus --apply   # one repo
#   ./forge-migrate.sh repoint  --repo luxfi/consensus --apply   # prove it
#   ./forge-migrate.sh repoint  --org lux --apply                # then batch
#
# Credentials: export HANZO_GIT_TOKEN (git.hanzo.ai admin token; value lives
# in KMS at hanzo/prod:/git/admin-token). Never inline it, never echo it.
# `status` and dry runs need no token for public repos.
set -uo pipefail

FORGE="https://git.hanzo.ai"
API="${FORGE}/api/v1"
APPLY=0
ORG_FILTER=""
REPO_ONE=""
CMD="${1:-status}"; shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --org)   ORG_FILTER="${2:-}"; shift ;;
    --repo)  REPO_ONE="${2:-}"; shift ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

# workdir : github-org : forge-org
ESTATE="
/Users/z/work/lux:luxfi:luxfi
/Users/z/work/hanzo:hanzoai:hanzo
/Users/z/work/zoo:zooai:zooai
"

API_CODE=000
API_BODY=""
# Sets the globals API_CODE / API_BODY. It deliberately does NOT print the
# body: a caller doing `x=$(api ...)` would run this in a subshell, and the
# API_CODE it set there would never reach the caller — every request would
# look like a 000 outage. Globals keep request and status in one scope.
api() { # method path [json-body]
  local m="$1" p="$2" d="${3:-}"
  local out hdr; out=$(mktemp); hdr=$(mktemp)
  # The token goes in a --config file, never on the command line: argv is
  # world-readable via ps, and this runs on shared runners. bash 3.2 (the
  # macOS default) also treats "${empty[@]}" as unbound under `set -u`, so
  # an args array is not an option here either.
  printf 'header = "Content-Type: application/json"\n' > "$hdr"
  [ -n "${HANZO_GIT_TOKEN:-}" ] && \
    printf 'header = "Authorization: token %s"\n' "${HANZO_GIT_TOKEN}" >> "$hdr"
  if [ -n "$d" ]; then
    API_CODE=$(curl -sS -o "$out" -w '%{http_code}' --max-time 45 -X "$m" \
      --config "$hdr" -d "$d" "${API}${p}" 2>/dev/null || echo 000)
  else
    API_CODE=$(curl -sS -o "$out" -w '%{http_code}' --max-time 45 -X "$m" \
      --config "$hdr" "${API}${p}" 2>/dev/null || echo 000)
  fi
  API_BODY=$(cat "$out")
  rm -f "$hdr" "$out"
}

forge_health() {
  api GET /version
  if [ "$API_CODE" != "200" ]; then
    echo "FORGE DOWN: ${FORGE} returned HTTP ${API_CODE}." >&2
    echo "The hanzo-git deployment (ns hanzo, hanzo-k8s) serves it and is OWNER-managed." >&2
    echo "Do NOT patch/restart/scale it to clear this. Re-run when it is healthy." >&2
    return 1
  fi
  echo "forge OK — gitea $(echo "$API_BODY" | sed 's/.*"version":"\([^"]*\)".*/\1/')"
}

repos_for() { # workdir -> repo basenames that are git checkouts
  local wd="$1" d
  for d in "$wd"/*/; do [ -d "$d/.git" ] && basename "${d%/}"; done
}

# The forge index, fetched ONCE into a file, then queried locally.
# 436 local repos x one API call each is ~7 minutes of round-trips for a
# question the paginated search endpoint answers in a few seconds.
FORGE_INDEX=""
load_forge_index() {
  FORGE_INDEX=$(mktemp)
  local page=1 got
  while :; do
    api GET "/repos/search?limit=50&page=${page}"
    [ "$API_CODE" = "200" ] || { echo "forge index fetch failed (HTTP ${API_CODE})" >&2; return 1; }
    local n; n=$(echo "$API_BODY" | grep -o '"full_name"' | wc -l | tr -d ' ')
    [ "$n" = 0 ] && break
    echo "$API_BODY" | tr ',' '\n' | sed -n 's/.*"full_name":"\([^"]*\)".*/\1/p' >> "$FORGE_INDEX"
    [ "$n" -lt 50 ] && break
    page=$((page+1))
  done
  sort -u -o "$FORGE_INDEX" "$FORGE_INDEX"
  echo "forge index: $(wc -l < "$FORGE_INDEX" | tr -d ' ') repos"
}
on_forge() { grep -qx "$1/$2" "$FORGE_INDEX"; }
trap '[ -n "$FORGE_INDEX" ] && rm -f "$FORGE_INDEX"' EXIT

# ── status ───────────────────────────────────────────────────────────
cmd_status() {
  forge_health || return 1
  load_forge_index || return 1
  printf '\n%-8s %-9s %-9s %-9s %-9s %s\n' ORG LOCAL "ON-FORGE" MISSING "ORIGIN=FORGE" NOTE
  local line wd gho fo
  for line in $ESTATE; do
    wd=${line%%:*}; rest=${line#*:}; gho=${rest%%:*}; fo=${rest#*:}
    [ -n "$ORG_FILTER" ] && [ "$(basename "$wd")" != "$ORG_FILTER" ] && continue
    local n=0 on=0 miss=0 pointed=0 r
    for r in $(repos_for "$wd"); do
      n=$((n+1))
      if on_forge "$fo" "$r"; then on=$((on+1)); else miss=$((miss+1)); fi
      git -C "$wd/$r" remote get-url origin 2>/dev/null | grep -q 'git\.hanzo\.ai' && pointed=$((pointed+1))
    done
    local note=""
    [ "$on" = 0 ] && note="BLOCKED — provision first"
    printf '%-8s %-9s %-9s %-9s %-9s %s\n' "$(basename "$wd")" "$n" "$on" "$miss" "$pointed" "$note"
  done
  echo
  echo "Also required before any repo adopts the mirror workflow:"
  echo "  org secret HANZO_GIT_TOKEN on hanzoai / luxfi / zooai"
  echo "  (projected from KMS hanzo/prod:/git/admin-token). Check with:"
  echo "    gh api orgs/<org>/actions/secrets --paginate --jq '.secrets[].name' | grep -x HANZO_GIT_TOKEN"
}

# ── provision ────────────────────────────────────────────────────────
# Create each missing repo on the forge as a PULL MIRROR of its GitHub
# remote. Pull-mirror (not push) is the architecture: the sync is defined
# once, server-side, so no write credential to the canonical forge ever
# needs to live in a GitHub secret store.
cmd_provision() {
  forge_health || return 1
  # A dry run is read-only, so it needs no credential — that is the whole
  # point of being able to review the plan before anyone holds the token.
  if [ "$APPLY" = 1 ] && [ -z "${HANZO_GIT_TOKEN:-}" ]; then
    echo "HANZO_GIT_TOKEN required to --apply (KMS hanzo/prod:/git/admin-token)." >&2; return 1
  fi
  load_forge_index || return 1
  local line wd gho fo r created=0 exists=0 failed=0
  for line in $ESTATE; do
    wd=${line%%:*}; rest=${line#*:}; gho=${rest%%:*}; fo=${rest#*:}
    [ -n "$ORG_FILTER" ] && [ "$(basename "$wd")" != "$ORG_FILTER" ] && continue
    for r in $(repos_for "$wd"); do
      if on_forge "$fo" "$r"; then exists=$((exists+1)); continue; fi
      if [ "$APPLY" = 0 ]; then
        echo "would create pull-mirror ${fo}/${r}  <-  github.com/${gho}/${r}"
        created=$((created+1)); continue
      fi
      # clone_addr uses HTTPS: the forge pulls, and public repos need no
      # credential. Private repos need auth_token on the migrate call —
      # add it deliberately, per repo, rather than blanket-embedding one.
      local body
      body=$(printf '{"clone_addr":"https://github.com/%s/%s.git","repo_name":"%s","repo_owner":"%s","mirror":true,"mirror_interval":"10m","private":false,"service":"git"}' \
             "$gho" "$r" "$r" "$fo")
      api POST /repos/migrate "$body"
      case "$API_CODE" in
        201) echo "created  ${fo}/${r}"; created=$((created+1)) ;;
        409) echo "exists   ${fo}/${r}"; exists=$((exists+1)) ;;
        *)   echo "FAILED   ${fo}/${r}  (HTTP ${API_CODE})" >&2; failed=$((failed+1)) ;;
      esac
    done
  done
  echo
  echo "created=${created} exists=${exists} failed=${failed}$([ "$APPLY" = 0 ] && echo '  (DRY RUN — pass --apply)')"
  [ "$failed" -gt 0 ] && return 1 || return 0
}

# ── convert ──────────────────────────────────────────────────────────
# Reverse the direction of the sync for one repo: pull mirror (GitHub
# canonical) -> normal repo (forge canonical, GitHub downstream).
#
# This is the step that actually makes git.hanzo.ai canonical, and it is
# the step with no safe bulk mode. While a repo is a pull mirror the forge
# OWNS its refs and overwrites them from GitHub on a timer; the moment it
# stops being one, nothing keeps the two in sync until a push mirror is
# added going the other way. Do it per repo, verify a real push lands, and
# only then move on. `--apply` converts exactly one repo (--repo o/n).
cmd_convert() {
  forge_health || return 1
  if [ -z "${REPO_ONE}" ]; then
    echo "convert takes exactly one repo: --repo <forge-org>/<name>" >&2; return 1
  fi
  if [ "$APPLY" = 1 ] && [ -z "${HANZO_GIT_TOKEN:-}" ]; then
    echo "HANZO_GIT_TOKEN required to --apply (KMS hanzo/prod:/git/admin-token)." >&2; return 1
  fi
  api GET "/repos/${REPO_ONE}"
  if [ "$API_CODE" != "200" ]; then
    echo "no such repo on forge: ${REPO_ONE} (HTTP ${API_CODE})" >&2; return 1
  fi
  if ! echo "$API_BODY" | grep -q '"mirror":true'; then
    echo "${REPO_ONE} is already a normal repo — nothing to convert."; return 0
  fi
  if [ "$APPLY" = 0 ]; then
    cat <<EOF
DRY RUN — would convert ${REPO_ONE} from pull mirror to canonical:
  1. DELETE ${API}/repos/${REPO_ONE}/mirror-sync-config   (stop pulling from GitHub)
     [Gitea exposes this as PATCH /repos/{o}/{r} {"mirror":false} on 1.26;
      confirm against this instance before --apply.]
  2. verify: GET /repos/${REPO_ONE} reports "mirror":false
  3. push a probe commit over HTTPS and confirm it survives >1 mirror tick
  4. add a PUSH mirror ${REPO_ONE} -> github.com so GitHub stays downstream
  5. only then: forge-migrate.sh repoint --repo ${REPO_ONE} --apply
EOF
    return 0
  fi
  api PATCH "/repos/${REPO_ONE}" '{"mirror":false}'
  if [ "$API_CODE" != "200" ]; then
    echo "convert FAILED for ${REPO_ONE} (HTTP ${API_CODE})" >&2; return 1
  fi
  api GET "/repos/${REPO_ONE}"
  if echo "$API_BODY" | grep -q '"mirror":true'; then
    echo "convert did NOT take for ${REPO_ONE} — still a mirror. Stop; do not repoint." >&2; return 1
  fi
  echo "converted ${REPO_ONE} — now canonical. Verify a real push lands before repointing."
}

# ── repoint ──────────────────────────────────────────────────────────
# origin -> git.hanzo.ai (canonical), github -> `mirror` remote.
# Per-repo gated: skips any repo whose forge copy is absent or EMPTY,
# because re-pointing origin at a repo that does not exist breaks every
# push for that repo. This is why it is not a blanket sed.
cmd_repoint() {
  forge_health || return 1
  load_forge_index || return 1
  local line wd gho fo r moved=0 skipped=0
  for line in $ESTATE; do
    wd=${line%%:*}; rest=${line#*:}; gho=${rest%%:*}; fo=${rest#*:}
    [ -n "$ORG_FILTER" ] && [ "$(basename "$wd")" != "$ORG_FILTER" ] && continue
    for r in $(repos_for "$wd"); do
      [ -n "$REPO_ONE" ] && [ "$REPO_ONE" != "${fo}/${r}" ] && continue
      local cur; cur=$(git -C "$wd/$r" remote get-url origin 2>/dev/null) || continue
      case "$cur" in *git.hanzo.ai*) continue ;; esac

      if ! on_forge "$fo" "$r"; then
        echo "skip  ${fo}/${r}  — not on forge; run provision first"
        skipped=$((skipped+1)); continue
      fi
      api GET "/repos/${fo}/${r}"
      if echo "$API_BODY" | grep -q '"empty":true'; then
        echo "skip  ${fo}/${r}  — forge copy is EMPTY; let the mirror finish its first pull"
        skipped=$((skipped+1)); continue
      fi
      # ── HARD REFUSAL: never point `origin` at a PULL MIRROR ────────
      # A pull mirror's upstream is GitHub. The forge re-runs
      #   git remote update --prune
      # (services/mirror/mirror_pull.go) on every tick, so a commit pushed
      # straight to the mirror is reverted — or pruned outright — minutes
      # later, with no error anywhere. Re-pointing origin here does not
      # make the forge canonical; it makes pushes silently disappear.
      # Convert the repo first (see `convert`), then re-point.
      if echo "$API_BODY" | grep -q '"mirror":true'; then
        echo "REFUSE ${fo}/${r}  — still a PULL MIRROR of GitHub; run 'convert' first (push here would be pruned)"
        skipped=$((skipped+1)); continue
      fi

      if [ "$APPLY" = 0 ]; then
        echo "would repoint ${wd}/${r}: origin -> ${FORGE}/${fo}/${r}.git  (github -> 'mirror')"
        moved=$((moved+1)); continue
      fi
      git -C "$wd/$r" remote remove mirror 2>/dev/null || true
      git -C "$wd/$r" remote add mirror "$cur"
      git -C "$wd/$r" remote set-url origin "${FORGE}/${fo}/${r}.git"
      echo "repointed ${wd}/${r}"
      moved=$((moved+1))
    done
  done
  echo
  echo "repointed=${moved} skipped=${skipped}$([ "$APPLY" = 0 ] && echo '  (DRY RUN — pass --apply)')"
}

case "$CMD" in
  status)    cmd_status ;;
  provision) cmd_provision ;;
  convert)   cmd_convert ;;
  repoint)   cmd_repoint ;;
  *) echo "usage: $0 {status|provision|convert|repoint} [--org lux|hanzo|zoo] [--repo o/n] [--apply]" >&2; exit 2 ;;
esac
