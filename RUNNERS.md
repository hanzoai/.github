# Self-hosted Runners — `arcd` Topology

All CI/CD for `hanzoai / luxfi / zooai / parsdao / zenlm` runs on **`arcd`** (source: [hanzoai/arc](https://github.com/hanzoai/arc) `cmd/arcd/`).

**ONE arcd binary per host serves ALL orgs.** Each daemon polls every org on a single tick, mints JIT runner configs on demand, spawns `actions-runner` subprocess per queued job, auto-deregisters on completion. Replaces ~26 per-org legacy installs per host.

GitHub-hosted runners (`ubuntu-latest`, `macos-latest`, `windows-latest`) are NOT a permitted fallback — pool labels below are the canonical replacement.

## Hosts (3 physical, 5 arcds)

Two hosts run two personalities each — one arcd per OS:

| Host | Personality | OS / Arch | Container | Service mgr | Endpoint |
|---|---|---|---|---|---|
| **dbc** (Apple Silicon M4 Max) | **macOS arm64** (Apple-native) | native | macOS | `~/Library/LaunchAgents/ai.hanzo.arcd.plist` (launchd) | `dbc:7777` |
| **dbc-linux** | **Linux arm64** | colima profile `arcd` (vz + Rosetta, 4cpu/8GB) | Ubuntu 24.04 in VM | `arcd.service` (systemd, in-VM) | `dbc:7777` inside VM |
| **evo** WSL | **Linux amd64** | WSL2 on Windows host | Ubuntu | `arcd.service` (systemd) | `evo:7777` |
| **evo** Windows | **Windows amd64** (Tauri `.msi`/`.exe`, Authenticode) | native | Windows | Scheduled Task `arcd` (AtLogOn, RestartCount=999) | `evo:7778` |
| **spark** (Ampere) | **Linux arm64** | native | Ubuntu | `arcd.service` (systemd) | `spark:7777` |

**Dual-personality hosts**: dbc serves both macOS (host) AND Linux arm64 (via colima VM). evo serves both Windows (native) AND Linux amd64 (via WSL2). Each personality is a separate arcd process with a distinct GitHub-reported OS, port, and config file — no conflict because they spawn different `actions-runner` binaries (`.exe` for Windows, ELF for Linux, Mach-O for macOS).

**spark** is single-personality (Linux arm64 only) but the largest box (3Ti disk, 121Gi RAM) — primary builder for the `<org>-linux-arm64` pool with dbc-linux as round-robin partner.

DO ARC scale-sets (`hanzo-build-linux-amd64`, `hanzo-deploy-linux-amd64`, `zoo-build-linux-amd64`, `lux-build-*`) remain online as ephemeral k8s capacity for amd64-only jobs that need horizontal scale.

## Pool labels (canonical)

Each arcd advertises a label set covering host + OS + arch + org-scoped pools. Workflows pin by pool label — GitHub round-robins to whichever runner picks up first.

| Pool label | Routes to | Use for |
|---|---|---|
| `<org>-macos-arm64` | dbc | macOS Apple-native (xcode/swift/cargo/brew) |
| `<org>-linux-arm64` | spark **+** dbc-linux | Linux aarch64 |
| `<org>-linux-amd64` | evo WSL | Linux amd64 |
| `<org>-windows-amd64` | evo Windows native | Tauri `.msi`, `.exe`, Authenticode |
| `<org>-wsl` | evo WSL only | WSL-specific tests |
| `dbc-<org>-macos`, `evo-<org>-windows`, `spark-<org>-linux` | exact-host pin | mac signing, GPU build, deterministic |
| `self-hosted` | any | catchall |

Replace `<org>` with `hanzoai` / `luxfi` / `zooai` / `parsdao` / `zenlm`. Per-host arcd configs:
- `~/.arcd/config.yaml` (host)
- `/Users/a/.arcd/config-linux.yaml` (dbc colima VM, mounted from host `~/.arcd`)
- `C:\arcd\config.yaml` (evo Windows)

## How to write workflows

### 1. Reusable Docker build → push GHCR (most common)

```yaml
jobs:
  docker:
    uses: hanzoai/.github/.github/workflows/docker-build.yml@main
    with:
      image: ghcr.io/<org>/<app>
      runner-amd64: <org>-amd64
      runner-arm64: <org>-arm64
      runner-deploy: hanzo-deploy-linux-amd64   # or lux-deploy-linux-amd64 etc.
    secrets: inherit
```

### 2. Cross-platform native release matrix (Tauri / CLI)

```yaml
on:
  workflow_dispatch:
  push: { tags: ['v*'] }

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        target:
          - { id: macos-arm64,   runner: <org>-macos-arm64,   tauri-target: aarch64-apple-darwin }
          - { id: linux-amd64,   runner: <org>-linux-amd64,   tauri-target: x86_64-unknown-linux-gnu }
          - { id: linux-arm64,   runner: <org>-linux-arm64,   tauri-target: aarch64-unknown-linux-gnu }
          - { id: windows-amd64, runner: <org>-windows-amd64, tauri-target: x86_64-pc-windows-msvc }
    runs-on: ${{ matrix.target.runner }}
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: pnpm tauri build --target ${{ matrix.target.tauri-target }}
      - uses: actions/upload-artifact@v4
        with:
          name: app-${{ matrix.target.id }}
          path: src-tauri/target/${{ matrix.target.tauri-target }}/release/bundle/**/*
```

Live examples:
- `hanzoai/desktop` `tauri-build-matrix.yml`, `hanzoai/worldmonitor` `release-matrix.yml`
- `hanzoai/build`, `operator`, `app`, `cli`, `cli` (CLI binaries)
- `luxfi/faucet`, `market`, `status` · `zooai/app`, `wallet`

### 3. Codesigning — `hanzoai/ci-signing` reusable workflows

Repo: https://github.com/hanzoai/ci-signing (public — reference directly, no fork needed)

Sign-only workflows per platform. Calling repo's matrix uploads the unsigned artifact; signing workflow downloads, signs, re-uploads as `<name>-signed`.

```yaml
jobs:
  build: ...    # produces 'app-macos-arm64', 'app-windows-amd64', 'app-linux-amd64'

  sign-macos:
    needs: build
    uses: hanzoai/ci-signing/.github/workflows/sign-macos.yml@v1
    with:
      artifact-name: app-macos-arm64
      runner: hanzoai-macos-arm64
    secrets: inherit

  sign-windows:
    needs: build
    uses: hanzoai/ci-signing/.github/workflows/sign-windows.yml@v1
    with:
      artifact-name: app-windows-amd64
      runner: hanzoai-windows-amd64
    secrets: inherit

  sign-linux:
    needs: build
    uses: hanzoai/ci-signing/.github/workflows/sign-linux.yml@v1
    with:
      artifact-name: app-linux-amd64
      runner: hanzoai-linux-amd64
    secrets: inherit
```

| Platform | Workflow | Mechanism | Cost |
|---|---|---|---|
| macOS | `sign-macos.yml` | Developer ID → notarize → staple → `.dmg` | $99/yr/org |
| iOS | `sign-ios.yml` | Apple Distribution → signed `.ipa` (+ TestFlight) | shares Apple Dev |
| Windows | `sign-windows.yml` | Azure Trusted Signing (OIDC) — jsign/YubiKey escape hatch inline | ~$120/yr total |
| Linux | `sign-linux.yml` | GPG detached `.asc` + `SHA256SUMS` (+ keyless cosign) | $0 |
| Android | `sign-android.yml` | upload keystore + Play upload | $25 once/org |

Org secrets already provisioned on hanzoai: `APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_PASSWORD`, `APPLE_SIGNING_IDENTITY`, `APPLE_TEAM_ID`. Provision others via `ci-signing/scripts/load-org-secrets.sh ORG=<org>`.

**Don't confuse with `hanzo/sign`** — that's the Documenso fork (document signing product), not code signing.

### 4. Pin a specific host (mac signing, GPU build)

```yaml
runs-on: dbc-luxfi-macos       # mac signing — needs Keychain on dbc
runs-on: spark-zooai-linux     # GPU build — spark has the Nvidia
runs-on: evo-hanzoai-windows   # Windows-native MSI build
```

## Installing / re-installing arcd

```bash
# Build cross-platform
cd ~/work/hanzo/arc
for tuple in "darwin arm64" "linux arm64" "linux amd64" "windows amd64"; do
  read goos goarch <<< "$tuple"
  ext=$([ "$goos" = "windows" ] && echo .exe)
  GOWORK=off GOOS=$goos GOARCH=$goarch CGO_ENABLED=0 \
    go build -o /tmp/arcd-builds/arcd-$goos-$goarch$ext ./cmd/arcd/
done

# Push to host + start. Each host has its own service unit (launchd/systemd/Scheduled Task).
# Configs in ~/.arcd/config.yaml; PAT in ~/.arcd/token; binary at ~/.arcd/arcd.
```

dbc colima setup (one-time):
```bash
colima start --profile arcd \
  --arch aarch64 --vm-type vz --vz-rosetta \
  --cpu 4 --memory 8 --disk 60 \
  --mount $HOME/.arcd:w
# Inside VM:
colima ssh -p arcd -- sudo systemctl enable --now arcd
```

(OrbStack networking has issues for our use case — use colima.)

## Operations

```bash
# Health across fleet
ssh dbc 'curl -s localhost:7777/healthz | jq -c'                                # macOS
ssh evo 'curl -s localhost:7777/healthz | jq -c'                                # WSL Linux
ssh evo 'curl -s localhost:7778/healthz | jq -c'                                # Windows native
ssh spark 'curl -s localhost:7777/healthz | jq -c'                              # spark
ssh dbc 'colima ssh -p arcd -- bash -c "curl -s localhost:7777/healthz"'        # dbc colima

# Restart
ssh dbc 'launchctl unload ~/Library/LaunchAgents/ai.hanzo.arcd.plist; launchctl load ~/Library/LaunchAgents/ai.hanzo.arcd.plist'
ssh evo 'sudo systemctl restart arcd'
ssh spark 'sudo systemctl restart arcd'
ssh dbc 'colima ssh -p arcd -- sudo systemctl restart arcd'
ssh evo '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "Stop-ScheduledTask -TaskName arcd; Start-Sleep 2; Start-ScheduledTask -TaskName arcd"'

# Verify runners on GitHub
for org in hanzoai luxfi zooai; do
  gh api /orgs/$org/actions/runners | jq -r '.runners[] | "  \(.name) [\(.status)] busy=\(.busy)"'
done
```

## Anti-patterns / don'ts

- **DON'T** install per-org `actions-runner` (one registration per host per org). That's the legacy model arcd replaces. If you see `~/actions-runner-<org>-<host>` dirs or `actions.runner.*.service` units → kill them.
- **DON'T** use GitHub-hosted runners. Pool labels are the replacement.
- **DON'T** assume `ubuntu-latest` routes to self-hosted. GitHub matches strictly; must use our pool labels.
- **DON'T** put codesigning secrets in repo. Org secrets → `secrets: inherit` to `hanzoai/ci-signing` workflows.
- **DON'T** confuse `hanzo/sign` (Documenso document signing) with `hanzoai/ci-signing` (CI code signing).
- **DON'T** use OrbStack for new arcd VMs. Use colima — fewer networking issues for this use case. OrbStack stays for separate k3d clusters.
- **DON'T** pin to a specific host label if any pool label works. Pool labels round-robin and survive single-host outages.
