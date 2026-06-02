# Self-hosted GitHub Actions Runners — Canonical Topology

All builds + deploys for `hanzoai/luxfi/zooai/parsdao/zenlm` orgs run on
**self-hosted runners only**. GitHub-hosted runners are not a permitted
fallback (cost, queueing, no native ARM, no GPU access, no code signing).

## Hosts

| Nickname | Hardware | OS | Arch | Capacity | Purpose |
|---|---|---|---|---|---|
| **spark** | Apple Silicon / Linux Ampere | Linux | arm64 | 121Gi RAM, 3Ti disk | Primary Linux arm64 builder |
| **evo** | x86_64 Windows host, WSL2 guest | Linux (WSL) | amd64 | 32 CPU, 102Gi RAM | Primary Linux amd64 builder, future Windows-native |
| **dbc** | Apple Silicon Mac (M-series) | macOS 26+ | arm64 | (M-series) | macOS-native + secondary arm64 builder |

Ephemeral capacity:
- **DO ARC pool** (`hanzo-build-linux-amd64`, max 30): k8s amd64 builders
- **DO ARC deploy** (`hanzo-deploy-linux-amd64`, max 20): k8s deploy jobs

## Per-org isolation (security)

Each host runs **one runner instance per org** — separate work directories,
log streams, registration scopes. GitHub enforces at registration time that
org-A workflows cannot dispatch to org-B runners. Zero cross-org bleeding.

Runner-instance layout per host:
```
~/actions-runner-hanzoai-<host>/
~/actions-runner-luxfi-<host>/
~/actions-runner-zooai-<host>/
```

Each registers via the org admin endpoint
(`/orgs/<org>/actions/runners/registration-token`) and installs a
systemd unit (Linux/WSL) or launchd plist (macOS).

## Labels — three tiers

Every runner carries **three label tiers** for selection flexibility:

```
self-hosted                     # standard
<host>-<org>-<arch>             # PIN: specific host (mac signing, GPU)
<host>-<org>-<os>               # PIN: by OS family
<org>-<arch>                    # POOL: round-robin any arch runner
<org>-<os>-<arch>               # POOL: round-robin by (os,arch)
<org>-<os>                      # POOL: round-robin by OS
```

GitHub auto-distributes work across all matching runners in a pool — first
free runner picks up the job. No queueing latency when ≥1 runner is idle.

### Full label matrix (live as of 2026-06-01)

| Host | hanzoai labels | luxfi labels | zooai labels |
|---|---|---|---|
| **spark** | `spark-hanzoai-arm64` `spark-hanzoai-linux` `hanzoai-arm64` `hanzoai-linux-arm64` `hanzoai-linux` | `spark-luxfi-arm64` `spark-luxfi-linux` `luxfi-arm64` `luxfi-linux-arm64` `luxfi-linux` | `spark-zooai-arm64` `spark-zooai-linux` `zooai-arm64` `zooai-linux-arm64` `zooai-linux` |
| **evo** | _(not installed)_ | `evo-luxfi-amd64` `evo-luxfi-linux` `luxfi-amd64` `luxfi-linux-amd64` `luxfi-linux` | `evo-zooai-amd64` `evo-zooai-linux` `zooai-amd64` `zooai-linux-amd64` `zooai-linux` |
| **dbc** | `dbc-hanzoai-arm64` `dbc-hanzoai-macos` `hanzoai-arm64` `hanzoai-macos-arm64` `hanzoai-macos` | `dbc-luxfi-arm64` `dbc-luxfi-macos` `luxfi-arm64` `luxfi-macos-arm64` `luxfi-macos` | `dbc-zooai-arm64` `dbc-zooai-macos` `zooai-arm64` `zooai-macos-arm64` `zooai-macos` |

## Desktop build matrix

Desktop apps (Hanzo Desktop, Zoo Desktop, Lux/AI Desktop — all Tauri-based)
need native builds per target. Map of (target → runner pool):

| Target | Pool label | Host(s) | Status |
|---|---|---|---|
| **macOS arm64** (Apple Silicon, primary) | `<org>-macos-arm64` | dbc | ✓ live |
| **macOS amd64** (Intel Mac, legacy) | `<org>-macos-amd64` | (none) | ⏳ need Intel Mac host |
| **Linux amd64** | `<org>-linux-amd64` | evo | ✓ live (luxfi, zooai) |
| **Linux arm64** | `<org>-linux-arm64` | spark | ✓ live |
| **Windows amd64** (native) | `<org>-windows-amd64` | evo's Windows host | ⏳ pending evo Windows-side runner install |
| **Windows arm64** (Surface ARM) | `<org>-windows-arm64` | (none) | ⏳ rare, defer |

For Tauri builds, a matrix workflow fans out across pools:

```yaml
jobs:
  build:
    strategy:
      matrix:
        target:
          - { os: macos-arm64,  runner: luxfi-macos-arm64,  tauri-target: aarch64-apple-darwin }
          - { os: linux-amd64,  runner: luxfi-linux-amd64,  tauri-target: x86_64-unknown-linux-gnu }
          - { os: linux-arm64,  runner: luxfi-linux-arm64,  tauri-target: aarch64-unknown-linux-gnu }
          - { os: windows-amd64,runner: luxfi-windows-amd64,tauri-target: x86_64-pc-windows-msvc }
    runs-on: ${{ matrix.target.runner }}
    steps:
      - uses: actions/checkout@v4
      - run: cargo tauri build --target ${{ matrix.target.tauri-target }}
```

## Local image registry per host

Each builder runs a local Docker registry on `localhost:5001` for buildx
cache. Saves bandwidth + speeds incremental builds significantly.

Install: `./scripts/setup-local-registry.sh` (in this repo).

Use as buildx cache target:
```yaml
- uses: docker/build-push-action@v6
  with:
    cache-from: type=registry,ref=localhost:5001/cache:${{ github.repository_id }}
    cache-to:   type=registry,ref=localhost:5001/cache:${{ github.repository_id }},mode=max
```

### Storage management (auto)

The setup script schedules a daily prune (`launchd` on macOS, `cron` on
Linux/WSL) at 3am local:
- **Disk < 80%**: keep last 7 days of layers
- **Disk ≥ 80%**: aggressive — `docker system prune -af` + registry GC

Monitor: `~/.docker-registry-prune.log`

## Installation

Single reusable script: `scripts/install-runner.sh`.

```bash
# On each host, for each org:
GH_RUNNER_TOKEN=$(gh api -X POST /orgs/<org>/actions/runners/registration-token | jq -r .token) \
  ./install-runner.sh <org> <host-nickname>

# Example: dbc setup for all 3 orgs:
for org in hanzoai luxfi zooai; do
  GH_RUNNER_TOKEN=$(gh api -X POST /orgs/$org/actions/runners/registration-token | jq -r .token) \
    ./install-runner.sh $org dbc
done

# Then local registry (one-time per host):
./scripts/setup-local-registry.sh
```

Detects platform (Linux / WSL / macOS), arch (amd64 / arm64), downloads
pinned runner version, registers org-scoped with the full 6-label set,
installs auto-restart service.

## Security posture

- **No public exposure**: hosts on private networks. Runners initiate
  outbound HTTPS only; zero inbound ports.
- **Per-org token scope**: registration tokens are org-scoped and expire
  in ~1 hour. Long-term identity is the runner's own credential file
  at `~/actions-runner-<org>-<host>/.credentials*` (mode 0600).
- **Worktree isolation**: per-org `_work/` — org-A jobs cannot read
  org-B build artifacts on the same physical host.
- **Label namespacing**: `<host>-<org>-<arch>` makes label collisions
  across orgs impossible.
- **No secrets in repo**: `GH_RUNNER_TOKEN` is ephemeral, env-only at
  install time. Workflow secrets flow via `secrets: inherit`.
- **Local registry is loopback-only**: `localhost:5001` not exposed off-host.

## Calling from workflows

### Cross-org caller (luxfi/<repo> → canonical workflow):

```yaml
jobs:
  docker:
    uses: hanzoai/.github/.github/workflows/docker-build.yml@main
    with:
      image: ghcr.io/luxfi/myapp
      # Pool labels — round-robin any free runner:
      runner-amd64: luxfi-amd64
      runner-arm64: luxfi-arm64
      runner-deploy: lux-deploy-linux-amd64   # ARC pool, pinned
    secrets: inherit
```

### Pin to specific host (mac signing, GPU build):

```yaml
jobs:
  mac-build:
    runs-on: dbc-luxfi-macos     # specifically dbc, not spark
    steps: [...]
```

## Operations

```bash
# Status across all runners on a host:
for d in ~/actions-runner-*; do echo "== $d =="; ( cd "$d" && ./svc.sh status ); done

# Restart a single runner:
( cd ~/actions-runner-luxfi-dbc && sudo ./svc.sh stop && sudo ./svc.sh start )

# Drain (let in-flight jobs finish):
( cd ~/actions-runner-luxfi-dbc && ./run.sh --once )

# Update runner version (rolling, one org at a time):
RUNNER_VER=2.322.0 GH_RUNNER_TOKEN=... ./install-runner.sh luxfi dbc

# Verify runners online for all orgs:
for org in hanzoai luxfi zooai; do
  gh api /orgs/$org/actions/runners | jq -r '.runners[] | "\(.name) [\(.status)]"'
done
```
