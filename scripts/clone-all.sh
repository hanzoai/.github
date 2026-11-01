#!/usr/bin/env bash
# ==============================================================================
# clone-all.sh — Concurrent, Idempotent Git Synchronizer for Hanzo Repositories
# ==============================================================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hanzoai/.github/main/scripts/clone-all.sh | bash
#   ./scripts/clone-all.sh [OPTIONS]
#
# Examples:
#   ./clone-all.sh                              # Clone all public hanzoai repos to ./hanzo-repos (SSH, 8 jobs)
#   ./clone-all.sh -o "hanzoai,hanzo-inc" -j 16 # Clone both OSS & Enterprise repos with 16 parallel workers
#   ./clone-all.sh --shallow                    # Fast shallow clone (--depth 1)
#   ./clone-all.sh --https                      # Use HTTPS instead of SSH
#   ./clone-all.sh --update                     # Pull latest changes on existing local checkouts
#   ./clone-all.sh --dry-run                    # List target repos without cloning
# ==============================================================================

set -euo pipefail

ORGS=("hanzoai")
BASE_DIR="${PWD}/hanzo-repos"
JOBS=8
USE_HTTPS=false
SHALLOW=false
UPDATE_EXISTING=true
INCLUDE_ARCHIVED=false
DRY_RUN=false

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

print_help() {
  echo -e "${BOLD}Hanzo AI Repository Synchronizer${NC}

${BOLD}USAGE:${NC}
  ./scripts/clone-all.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
  -o, --orgs <list>       Comma-separated GitHub organizations (default: \"hanzoai\", or \"hanzoai,hanzo-inc\")
  -d, --dir <path>        Base destination directory (default: \"./hanzo-repos\")
  -j, --jobs <n>          Number of concurrent clone/fetch jobs (default: 8)
      --https             Clone via HTTPS instead of SSH (git@github.com)
      --shallow           Perform shallow clones (--depth 1) for fast checkout
      --no-update         Skip fetching/pulling if repository already exists locally
      --archived          Include archived repositories (default: skipped)
      --dry-run           Print repository list and planned actions without executing
  -h, --help              Show this help message"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--orgs) IFS=',' read -r -a ORGS <<< "$2"; shift 2 ;;
    -d|--dir) BASE_DIR="$2"; shift 2 ;;
    -j|--jobs) JOBS="$2"; shift 2 ;;
    --https) USE_HTTPS=true; shift ;;
    --shallow) SHALLOW=true; shift ;;
    --no-update) UPDATE_EXISTING=false; shift ;;
    --update) UPDATE_EXISTING=true; shift ;;
    --archived) INCLUDE_ARCHIVED=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo -e "${RED}Unknown option:${NC} $1" >&2; print_help; exit 1 ;;
  esac
done

if ! command -v gh &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) is required.${NC} Install it via https://cli.github.com" >&2
  exit 1
fi

if ! command -v git &> /dev/null; then
  echo -e "${RED}Error: git is required.${NC}" >&2
  exit 1
fi

echo -e "${BOLD}${CYAN}=== Hanzo Repository Fleet Synchronizer ===${NC}"
echo -e "Organizations : ${GREEN}${ORGS[*]}${NC}"
echo -e "Target Dir    : ${BLUE}${BASE_DIR}${NC}"
echo -e "Protocol      : $(if [ "$USE_HTTPS" = true ]; then echo "HTTPS"; else echo "SSH"; fi)"
echo -e "Parallel Jobs : ${JOBS}"
echo -e "Shallow Clone : ${SHALLOW}"
echo ""

mkdir -p "${BASE_DIR}"
MANIFEST_FILE=$(mktemp)
trap 'rm -f "$MANIFEST_FILE"' EXIT

for org in "${ORGS[@]}"; do
  echo -e "${BLUE}Fetching repository manifest for:${NC} ${BOLD}${org}${NC}..."
  TEMPLATE='{{range .}}'
  [ "$INCLUDE_ARCHIVED" = false ] && TEMPLATE+='{{if not .isArchived}}'
  TEMPLATE+='{{.name}} {{.sshUrl}} {{.url}}{{"\n"}}'
  [ "$INCLUDE_ARCHIVED" = false ] && TEMPLATE+='{{end}}'
  TEMPLATE+='{{end}}'

  gh repo list "$org" --limit 1000 --json name,sshUrl,url,isArchived --template "$TEMPLATE" | while read -r name ssh_url https_url; do
    if [ -n "$name" ]; then
      if [ "$USE_HTTPS" = true ]; then
        echo "$org $name $https_url" >> "$MANIFEST_FILE"
      else
        echo "$org $name $ssh_url" >> "$MANIFEST_FILE"
      fi
    fi
  done
done

TOTAL_REPOS=$(wc -l < "$MANIFEST_FILE" | tr -d ' ')
echo -e "${GREEN}Found ${TOTAL_REPOS} total repositories to sync.${NC}\n"

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}[DRY RUN] Target directories and clone URLs:${NC}"
  while read -r org name url; do
    echo "  - ${BASE_DIR}/${org}/${name} <== ${url}"
  done < "$MANIFEST_FILE"
  exit 0
fi

sync_repo() {
  local org="$1" name="$2" url="$3" base_dir="$4" shallow="$5" update_existing="$6"
  local target_dir="${base_dir}/${org}/${name}"

  if [ -d "${target_dir}/.git" ]; then
    if [ "$update_existing" = "true" ]; then
      printf "\033[0;33m[UPDATE]\033[0m %s/%s...\n" "$org" "$name"
      git -C "$target_dir" fetch --all --prune --quiet 2>/dev/null || true
      local default_branch
      default_branch=$(git -C "$target_dir" symbolic-ref --short HEAD 2>/dev/null || echo "")
      [ -n "$default_branch" ] && git -C "$target_dir" pull --ff-only --quiet 2>/dev/null || true
    else
      printf "\033[0;37m[SKIP]\033[0m   %s/%s (already exists)\n" "$org" "$name"
    fi
  else
    printf "\033[0;32m[CLONE]\033[0m  %s/%s...\n" "$org" "$name"
    mkdir -p "$(dirname "$target_dir")"
    local clone_args=("--quiet")
    [ "$shallow" = "true" ] && clone_args+=("--depth" "1")
    if git clone "${clone_args[@]}" "$url" "$target_dir" 2>/dev/null; then
      printf "\033[0;32m[DONE]\033[0m   %s/%s\n" "$org" "$name"
    else
      printf "\033[0;31m[ERROR]\033[0m  Failed to clone %s/%s\n" "$org" "$name" >&2
    fi
  fi
}

export -f sync_repo
xargs -a "$MANIFEST_FILE" -n 3 -P "$JOBS" bash -c 'sync_repo "$1" "$2" "$3" "'"$BASE_DIR"'" "'"$SHALLOW"'" "'"$UPDATE_EXISTING"'"' _

echo -e "\n${BOLD}${GREEN}✔ Sync complete!${NC} All repositories are organized in ${BLUE}${BASE_DIR}${NC}"
