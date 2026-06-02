# Self-hosted GitHub Actions Runners — Canonical Topology

All builds + deploys for hanzoai/luxfi/zooai/parsdao/zenlm orgs run on
**self-hosted runners only**. GitHub-hosted runners are not a permitted
fallback (cost, queueing, no native ARM, no GPU access).

## Hosts

| Nickname | Hardware | OS | Arch | Capacity | Purpose |
|---|---|---|---|---|---|
| **spark** | Apple Silicon Mac / Linux Ampere | macOS / Linux | arm64 | 121Gi RAM, 3Ti disk | Primary arm64 builder |
| **evo** | Windows-host x86_64, WSL2 guest | Linux (WSL) / Windows | x86_64 | 32 CPU, 102Gi RAM | Primary amd64 + Windows native |
| **dbc** | Apple Silicon Mac (M-series) | macOS 26+ | arm64 | (M-series) | Secondary arm64 + macOS native builder |

Additional ephemeral capacity:
- **DO ARC pool** (`hanzo-build-linux-amd64`, max 30): k8s-based amd64 builders
- **DO ARC deploy** (`hanzo-deploy-linux-amd64`, max 20): k8s-based deploy jobs

## Per-org isolation

Each host runs **one runner instance per org** — they share hardware but
have separate work directories, log streams, and registration scopes.
GitHub enforces at registration time that org-A workflows cannot
dispatch to org-B-labelled runners — no cross-org bleeding.

Runner-instance layout per host:

```
~/actions-runner-hanzoai-<host>/
~/actions-runner-luxfi-<host>/
~/actions-runner-zooai-<host>/
```

Each registers with the GitHub org admin endpoint
(`/orgs/<org>/actions/runners/registration-token`) and installs a
systemd unit (Linux/WSL) or launchd plist (macOS) named
`actions.runner.<org>.<runner-name>.service`.

## Canonical labels

`<host>-<org>-<arch>` is the unique selector. Workflows pin via:

```yaml
runs-on: spark-luxfi-arm64        # arm64 build on spark for luxfi
runs-on: evo-hanzoai-x86_64       # amd64 build on evo for hanzoai
runs-on: dbc-zooai-arm64          # arm64 build on dbc for zooai
```

Full label matrix:

| Host | hanzoai | luxfi | zooai |
|---|---|---|---|
| **spark** | `spark-hanzoai-arm64` `spark-hanzoai-linux` | `spark-luxfi-arm64` `spark-luxfi-linux` | `spark-zooai-arm64` `spark-zooai-linux` |
| **evo** | `evo-hanzoai-x86_64` `evo-hanzoai-linux` | `evo-luxfi-x86_64` `evo-luxfi-linux` | `evo-zooai-x86_64` `evo-zooai-linux` |
| **dbc** | `dbc-hanzoai-arm64` `dbc-hanzoai-macos` | `dbc-luxfi-arm64` `dbc-luxfi-macos` | `dbc-zooai-arm64` `dbc-zooai-macos` |

All runners also carry the standard `self-hosted` label.

## Installation

Single reusable script: `scripts/install-runner.sh` (in this repo).

```bash
# On each host, for each org:
GH_RUNNER_TOKEN=$(gh api -X POST /orgs/<org>/actions/runners/registration-token | jq -r .token) \
  ./install-runner.sh <org> <host>

# Examples:
GH_RUNNER_TOKEN=... ./install-runner.sh hanzoai dbc
GH_RUNNER_TOKEN=... ./install-runner.sh luxfi   dbc
GH_RUNNER_TOKEN=... ./install-runner.sh zooai   dbc
```

Script detects platform (Linux / WSL / macOS), arch (x86_64 / arm64),
downloads pinned runner version, registers org-scoped with correct
labels, and installs an auto-restart service.

## Security

- **No public exposure**: hosts are on private networks. Runners initiate
  outbound HTTPS to GitHub; no inbound ports needed.
- **Per-org token scope**: registration tokens are org-scoped, expire in
  ~1 hour. Long-term identity is the runner's own credential file under
  `~/actions-runner-<org>-<host>/.credentials*`.
- **Worktree isolation**: each runner instance has its own `_work/` —
  org-A jobs cannot read org-B build artifacts.
- **Label namespacing**: `<host>-<org>-<arch>` makes label collisions
  impossible across orgs.
- **No secrets in repo**: `GH_RUNNER_TOKEN` is ephemeral, passed via env
  only during installation. Workflow secrets flow via `secrets: inherit`
  to the canonical reusable workflow.

## Calling from workflows

Cross-org callers MUST override the runner defaults in the canonical
`docker-build.yml` reusable workflow.

```yaml
# luxfi/<repo>/.github/workflows/docker.yml
jobs:
  docker:
    uses: hanzoai/.github/.github/workflows/docker-build.yml@main
    with:
      image: ghcr.io/luxfi/myapp
      runner-amd64: lux-build-linux-amd64     # DO ARC pool for luxfi
      runner-arm64: spark-luxfi-arm64         # OR dbc-luxfi-arm64 if spark is busy
      runner-deploy: lux-deploy-linux-amd64
    secrets: inherit
```

For macOS-native builds (signing, notarization), pin directly:

```yaml
jobs:
  mac-build:
    runs-on: dbc-luxfi-macos
    steps: [...]
```

For Windows-native builds (when an evo Windows runner is registered):

```yaml
jobs:
  win-build:
    runs-on: evo-luxfi-windows
    steps: [...]
```

## Operations

```bash
# Status across all runners on a host:
for d in ~/actions-runner-*; do echo "== $d =="; ( cd "$d" && ./svc.sh status ); done

# Restart a single runner:
( cd ~/actions-runner-luxfi-dbc && sudo ./svc.sh stop && sudo ./svc.sh start )

# Drain (let in-flight jobs finish, stop accepting new):
( cd ~/actions-runner-luxfi-dbc && ./run.sh --once ) # one job then exit

# Update runner version (rolling, one org at a time):
RUNNER_VER=2.322.0 GH_RUNNER_TOKEN=... ./install-runner.sh luxfi dbc
```
