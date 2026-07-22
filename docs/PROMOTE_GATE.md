# Pre-Promote E2E Gate

**Promoting a production operator CR image tag by hand is DEPRECATED.** Every
prod tag bump goes through the reusable workflow
[`.github/workflows/promote.yml`](../.github/workflows/promote.yml), so a
staging deploy + Playwright E2E gates every change before it reaches the
operator CR — the one thing the old `.platform.yml` → operator path and manual
CR edits never had.

## Why

The canonical prod path is: build an image → `.platform.yml` → platform.hanzo.ai
→ the Rust operator writes `image.tag` into
`hanzoai/universe:infra/k8s/operator/crs/<service>.yaml` → argocd/operator rolls
it live. There was **no test gate** between "image built" and "live", and the
same CR also gets hand-edited. `promote.yml` inserts a mandatory, fail-closed
gate and makes itself the **only** sanctioned writer of a prod CR tag.

It also catches a failure mode a rolling prod deploy hides: a
`strategy: Recreate` service whose new image never becomes Ready dies silently
under `maxUnavailable`. In staging the throwaway rollout simply never completes,
so the gate blocks.

## The gate (fail-closed job DAG)

```
stage ──▶ e2e ──▶ promote ──▶ (all three) ──▶ cleanup
```

1. **stage** — deploys `image:tag` into a throwaway namespace
   `staging-<service>-<run_id>` on `do-sfo3-hanzo-k8s`: a 1-replica Deployment
   with a `readinessProbe` on `health-path:port` + Service, then
   `kubectl rollout status --timeout=180s`. Un-pullable / crash-looping /
   never-Ready image ⇒ rollout times out ⇒ **blocked**.
2. **e2e** — port-forwards the staged Service (`kubectl port-forward
   svc/<service> 8080:<port>`, no new public DNS) and runs the repo's Playwright
   suite against `http://localhost:8080`. If the repo has no `playwright.config.*`
   it falls back to a **smoke floor** (GET `health-path` must be 2xx/3xx **and**
   return a non-empty body) — never auto-pass. Any failure ⇒ **blocked**.
3. **promote** — the **only** writer of the prod CR. Runs iff `stage` is green
   **and** `e2e` passed (or was intentionally disabled). Sets `.spec.image.tag`
   via a surgical `yq` edit, commits `chore(promote): <service> → <tag>
   (E2E-gated)`, pushes to `main`. argocd/operator syncs it to prod.
4. **cleanup** — `if: always()` deletes the staging namespace.

### There is no bypass

`promote`'s condition is:

```yaml
if: ${{ !cancelled()
        && needs.stage.result == 'success'
        && (needs.e2e.result == 'success' || needs.e2e.result == 'skipped') }}
```

- stage failed → e2e skips → promote skips.
- e2e failed → promote skips.
- e2e disabled (`e2e-enabled: false`) → e2e is `skipped`, but promote **still
  requires `stage == 'success'`** — an image that can't even roll in staging is
  never promoted.
- run cancelled → promote skips.

The tag edit is enforced surgical at runtime: after `yq -i
'.spec.image.tag = strenv(TAG)'`, the job asserts `git diff --numstat` is
exactly `1 1` (one line added, one removed) and reads the value back; any
collateral change aborts the promotion before commit.

## How to adopt it

Call `promote.yml` right after your build job, feeding it the freshly-built
semver tag (no leading `v`, per repo convention):

```yaml
jobs:
  build:
    uses: hanzoai/.github/.github/workflows/docker-build.yml@main
    with:
      image: ghcr.io/hanzoai/iam
    secrets: inherit

  promote:
    needs: build
    uses: hanzoai/.github/.github/workflows/promote.yml@main
    with:
      service: iam                              # → staging ns + crs/iam.yaml
      image: ghcr.io/hanzoai/iam                # GHCR ref WITHOUT the tag
      tag: ${{ needs.build.outputs.version }}   # semver, no leading v
      port: "8000"
      health-path: /
    secrets: inherit
```

### Inputs

| Input | Default | Meaning |
|---|---|---|
| `service` | — (required) | staging namespace + CR filename (`crs/<service>.yaml`) |
| `image` | — (required) | GHCR ref **without** the tag |
| `tag` | — (required) | candidate semver tag (no `v`); used verbatim |
| `port` | `3000` | container port |
| `health-path` | `/` | readinessProbe + smoke path |
| `e2e-dir` | `.` | caller-repo dir holding `playwright.config.*` |
| `crs-repo` | `hanzoai/universe` | repo holding the CRs |
| `crs-path` | `infra/k8s/operator/crs` | CR directory within `crs-repo` |
| `e2e-enabled` | `true` | run E2E; `false` still requires a green staging rollout |
| `kube-context` | `""` | optional kubectl context (empty = runner default) |

Cross-repo promotion (the default — CRs live in `hanzoai/universe`) requires the
`GH_PAT` secret; `GITHUB_TOKEN` can't push to another repo. The workflow fails
early with a clear message if it's missing.
