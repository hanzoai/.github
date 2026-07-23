# Self-hosted Runners — `act_runner` Topology (post-`arcd`)

All CI for `hanzoai / luxfi / zooai / parsdao / zenlm` runs on **Hanzo Git
Actions** (`git.hanzo.ai`) executed by **`act_runner`** — the ONE runner.
`arcd` is retired (see [`docs/architecture/runners-act-migration.md`](../universe/docs/architecture/runners-act-migration.md)
in `hanzoai/universe` for the cutover runbook + `arcd` teardown).

**This file is the single source of truth for the runner label taxonomy.**
Both the runner configs (`hanzoai/universe:infra/runners/*` and
`infra/k8s/git-runner/`) and every workflow's `runs-on` consume the table
below. The older `hanzoai/arc:scripts/RUNNERS.md` and
`hanzoai/universe:infra/runners/README.md` are subordinate — they point here.

## Model — one runner, capability-routed

`act_runner` (nektos/act engine) registers against Hanzo Git and long-polls
`/api/actions` for queued jobs. It reads GitHub-Actions-compatible YAML, so
`.github/workflows/*` (and the forward-canonical `.hanzo/workflows/*`) run
unmodified — the Hanzo Git server sets `DEFAULT_ACTIONS_URL=github`, so
`uses: actions/checkout@v4` resolves against github.com.

Execution is **decomplected from the host by capability**:

- The **in-cluster DinD StatefulSet** (`infra/k8s/git-runner/`, `docker`
  executor) serves the fungible **amd64-Linux bulk** — zero physical-host
  dependency, horizontally scalable on the `ci-runner` node pool.
- **Native host-executor runners** on BYO hosts serve only what the cluster
  cannot: **Metal GPU** + **macOS** (dbc), **Windows** (evo), **Linux
  arm64 + CUDA** (spark), **WSL / Vulkan** (evo-WSL).

A `runs-on` value names a **capability**, not a box. A runner advertises the
**union** of every label-value that routes to it, so the same job matches
whether it asks for the canonical compound label, a generic capability
token, or a GitHub-hosted name.

## Label formula — author against the canonical, everything else is a compat alias

The **canonical** label for new workflows is the compound
**`<org>-<os>-<arch>`**:

| axis | values |
|---|---|
| `<org>` | `hanzo` · `lux` · `zoo` · `pars` · `zen` (long-org `hanzoai`/`luxfi`/`zooai` also advertised, for the `ci-signing` reusables) |
| `<os>` | `linux` · `macos` · `windows` |
| `<arch>` | `amd64` · `arm64` |

Every runner ALSO advertises, for backward compatibility, the set of aliases
that route to the same capability:

1. **Generic capability tokens** — for list-form `runs-on: [self-hosted, <os>, <arch>]`:
   `self-hosted`, `linux`/`Linux`, `macos`/`macOS`/`darwin`/`Darwin`,
   `windows`/`Windows`, `amd64`/`x64`/`X64`, `arm64`/`ARM64`/`aarch64`.
2. **GitHub-hosted names** — `ubuntu-latest`/`-24.04`/`-22.04`/`-20.04`,
   `macos-latest`/`-15`/`-14`/`-13`, `windows-latest`/`-2022`.
3. **Legacy purpose labels** already in the tree — `hanzo-build-linux-amd64`,
   `hanzo-deploy-linux-amd64`, `hanzo-docs-build-linux-amd64`,
   `lux-build-amd64`, `lux-build`, `hanzoai-amd64`, `hanzo-build-darwin-arm64`, …
4. **Accelerator tokens** — `metal`/`m4max` (dbc), `gpu`/`cuda`/`nvidia`
   (spark), `vulkan`/`radeon`/`hip-windows` (evo).
5. **Host pin** — `dbc` / `spark` / `evo` / `evo-windows`.

New workflows SHOULD use the canonical compound. Existing `runs-on` lines
keep working unchanged — that is the whole point of the union.

## Authoritative pool table

| Pool (canonical) | Executor | Host | Advertises (union) |
|---|---|---|---|
| `<org>-linux-amd64` | `docker` (catthehacker act-24.04) | **in-cluster DinD** (+ evo-WSL overflow) | `ubuntu-latest`·`ubuntu-24.04`·`ubuntu-22.04`·`ubuntu-20.04`, `self-hosted`·`linux`·`Linux`·`amd64`·`x64`·`X64`·`available`, `hanzoai-linux-amd64`·`luxfi-linux-amd64`·`lux-amd64`, `hanzo-build-linux-amd64`·`hanzo-deploy-linux-amd64`·`hanzo-docs-build-linux-amd64`·`hanzo-apps-build-linux-amd64`·`hanzoai-amd64`, `lux-build-amd64`·`lux-build-linux-amd64`·`lux-build`·`lux-docs-build`·`luxbank-build`, `{zoo,pars,zen}-build-linux-amd64` |
| `<org>-linux-arm64` | `docker` (catthehacker act-24.04) + GPU passthrough | **spark** | `ubuntu-24.04-arm`·`ubuntu-22.04-arm`, `self-hosted`·`linux`·`Linux`·`arm64`·`ARM64`·`aarch64`, `hanzoai-linux-arm64`·`luxfi-linux-arm64`·`hanzoai-arm64`·`lux-arm64`, `lux-build-linux-arm64`·`hanzo-build-linux-arm64`·`hanzo-build-arm64`·`lux-build-arm64`, `spark` |
| `<org>-macos-arm64` | `host` (Apple-native, Metal) | **dbc** (M4 Max) | `macos-latest`·`macos-15`·`macos-14`·`macos-13`·`macos-26`, `self-hosted`·`macos`·`macOS`·`darwin`·`Darwin`·`arm64`·`ARM64`·`aarch64`·`apple-silicon`, `hanzo-build-darwin-arm64`, `metal`·`m4max`·`gpu-metal`, `dbc` |
| `<org>-windows-amd64` | `host` (Windows-native) | **evo** (Windows) | `windows-latest`·`windows-2022`, `self-hosted`·`windows`·`Windows`·`amd64`·`x64`·`X64`, `radeon`·`vulkan`·`hip-windows`, `evo-windows` |
| `<org>-wsl` | `docker` (catthehacker act-24.04) | **evo** (WSL2) | `self-hosted`·`linux`·`Linux`·`amd64`·`x64`·`X64`·`available`, `wsl`·`vulkan`·`radeon`, `evo` |
| `<org>-gpu-cuda` | `docker` + `--gpus all` (job sets `container:` CUDA image) | **spark** (Blackwell) | `gpu`·`cuda`·`nvidia`·`cuda-arm64` — matches `[self-hosted, gpu, cuda]`, `[self-hosted, cuda]` |

Replace `<org>` with `hanzo`/`lux`/`zoo`/`pars`/`zen`. Per-host runner
configs materialise the exact union: `hanzoai/universe:infra/runners/<host>/config.yaml`
(dbc, spark, evo-wsl, evo-windows) + the in-cluster `infra/k8s/git-runner/statefulset.yaml`
(`GITEA_RUNNER_LABELS`).

### Documented external / owner-gated pools (NOT on the dbc/evo/spark fleet)

These `runs-on` values are intentionally **not** served by the core fleet;
they are honest gaps, not silent fallbacks:

| `runs-on` | Home | Note |
|---|---|---|
| `[self-hosted, gpu, cuda, h100]` | dedicated **luxcpp CUDA host** | H100/sm_90. spark is Blackwell (sm_100); it serves `[self-hosted, gpu, cuda]` only. The luxcpp box registers to `git.hanzo.ai` with the SAME `infra/runners/register.sh` pattern (`--personality cuda-h100`), advertising `gpu cuda h100 nvidia`. |
| `[self-hosted, macOS, X64]` | osxcross on `<org>-linux-amd64` | Intel-Mac pool retired. `darwin/amd64` builds cross-compile via `ghcr.io/luxcpp/osxcross-sdk` on the amd64 pool (see `lux-private/cevm:cevm-plugin-release.yml`). Rewrite any surviving `[self-hosted, macOS, X64]` job to the osxcross lane. |
| `windows-11-arm` | — | No Windows-arm64 host in fleet. Add a host or drop the target. |

### Out of scope — upstream-fork CI (uses SaaS/upstream runners, not Hanzo's fleet)

Repos that are upstream forks carry their own runner conventions and do NOT
build on the Hanzo fleet. Their labels are deliberately excluded:
`amd-medium`/`arm-large`/`style-checker*` (ClickHouse — `hanzo/datastore*`),
`hyperswitch-runners*` (`hanzo/payments`), `langflow-ai-*` (`hanzo/flow`),
`depot-ubuntu-*`/`namespace-profile-*`/`warp-ubuntu-*`/`oracle-bare-metal-*`/`aws-mac*-metal`
(`hanzo/evm`, `auto`, `esign`, `ledger`, `numscript`, `pubsub`, `telemetry-go`, `lux/torus-stage`).

## Hosts

| Host | Personality | OS / Arch | Executor | Service unit |
|---|---|---|---|---|
| **in-cluster** | DinD StatefulSet ×2 | Linux amd64 (containers) | `docker` | `infra/k8s/git-runner/statefulset.yaml` |
| **dbc** (Apple M4 Max, Metal 4) | macOS-native + Metal | macOS arm64 | `host` | `~/Library/LaunchAgents/ai.hanzo.git-runner.plist` (per-user LaunchAgent) |
| **spark** (GB10 Grace-Blackwell) | Linux arm64 + CUDA | Linux arm64 | `docker` | `git-runner.service` (systemd) |
| **evo** — WSL2 | Linux amd64 (WSL/Vulkan) | Linux amd64 | `docker` | `git-runner.service` (systemd, in-WSL) |
| **evo** — Windows | Windows-native | Windows amd64 | `host` | Scheduled Task `HanzoGitRunner` (AtLogOn) |

### dbc macOS + Metal/GPU jobs — GUI-session requirement (unchanged, now on `act_runner`)

`MTLCreateSystemDefaultDevice()` returns **nil** unless the `act_runner`
process runs inside a logged-in **Aqua (GUI) window-server session** — a
headless / SSH / LaunchDaemon context has no Metal device, and GPU host
factories then silently fall back to CPU (a false green). The runner is a
per-user **LaunchAgent** (`~/Library/LaunchAgents/ai.hanzo.git-runner.plist`),
loaded into the GUI domain (`launchctl bootstrap gui/$(id -u) …`), which is
the correct category — same slot the retired `ai.hanzo.arcd` LaunchAgent held.

Operational requirement: dbc must **auto-login to the desktop and keep an
active, unlocked GUI session**. Verify:
`ssh dbc 'launchctl print gui/$(id -u)/ai.hanzo.git-runner | grep -i state'`.
Metal-dispatch CI (`lux-private/cevm:.github/workflows/gpu-metal.yml`)
**asserts a real device** (fails on `Metal device unavailable`) so a
regressed/headless session turns the job RED instead of silently skipping.

## How to write workflows

### 1. Reusable Docker build → push GHCR (most common)

```yaml
jobs:
  docker:
    uses: hanzoai/.github/.github/workflows/docker-build.yml@main
    with:
      image: ghcr.io/<org>/<app>
      runner-amd64: hanzo-linux-amd64     # canonical compound
      runner-arm64: hanzo-linux-arm64
      runner-deploy: hanzo-linux-amd64
    secrets: inherit
```

### 2. Cross-platform native release matrix (Tauri / CLI)

```yaml
on: { workflow_dispatch: {}, push: { tags: ['v*'] } }
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        target:
          - { id: macos-arm64,   runner: hanzo-macos-arm64,   rust: aarch64-apple-darwin }
          - { id: linux-amd64,   runner: hanzo-linux-amd64,   rust: x86_64-unknown-linux-gnu }
          - { id: linux-arm64,   runner: hanzo-linux-arm64,   rust: aarch64-unknown-linux-gnu }
          - { id: windows-amd64, runner: hanzo-windows-amd64, rust: x86_64-pc-windows-msvc }
    runs-on: ${{ matrix.target.runner }}
    steps:
      - uses: actions/checkout@v4
      - run: pnpm tauri build --target ${{ matrix.target.rust }}
      - uses: actions/upload-artifact@v4
        with: { name: app-${{ matrix.target.id }}, path: src-tauri/target/${{ matrix.target.rust }}/release/bundle/**/* }
```

### 3. Codesigning — `hanzoai/ci-signing` reusable workflows

Mirror `hanzoai/ci-signing` to `git.hanzo.ai` first (see the runbook), then
`uses: hanzoai/ci-signing/.github/workflows/sign-<plat>.yml@v1`. Pass
`runner: hanzoai-macos-arm64` / `hanzoai-windows-amd64` / `hanzoai-linux-amd64`
(the long-org aliases the fleet advertises for this reusable's convention).

| Platform | Workflow | Mechanism |
|---|---|---|
| macOS | `sign-macos.yml` | Developer ID → notarize → staple → `.dmg` |
| iOS | `sign-ios.yml` | Apple Distribution → signed `.ipa` |
| Windows | `sign-windows.yml` | Azure Trusted Signing (OIDC) |
| Linux | `sign-linux.yml` | GPG `.asc` + `SHA256SUMS` (+ cosign) |
| Android | `sign-android.yml` | keystore + Play upload |

Provision org/instance secrets on `git.hanzo.ai` (`APPLE_*`, GHCR PAT, Azure
OIDC) — see the runbook's owner-gated section.

**Don't confuse `hanzo/sign`** (Documenso document signing) with
`hanzoai/ci-signing` (CI code signing).

### 4. Pin a specific host (mac signing, GPU build)

```yaml
runs-on: dbc            # mac signing — needs Keychain + Metal on dbc
runs-on: spark          # CUDA build — spark has the Blackwell GPU
runs-on: evo-windows    # Windows-native MSI build
```

## Reusable / marketplace-action notes (Hanzo Git)

- **Reusable workflows must be mirrored** to `git.hanzo.ai` before use —
  `hanzoai/.github`, `luxfi/.github`, `hanzoai/ci-signing` (`@main` / `@v1`).
  A `uses: hanzoai/.github/...@main` resolves against Hanzo Git, not github.com.
- **Marketplace `uses: actions/*`, `docker/*`, `softprops/*`** resolve from
  github.com via `DEFAULT_ACTIONS_URL=github` — no mirror needed.
- **`GITHUB_TOKEN`** issued by Hanzo Git is scoped to `git.hanzo.ai`, not
  `ghcr.io`. `docker-build` consumers push with a GHCR PAT secret.
- **Drop SaaS-only steps** with no sovereign equivalent: `github/codeql-action`,
  `codecov/*`. Cache + artifacts are served natively (act_runner cache server
  + Hanzo Git artifacts, 30-day retention).

## Operations

```bash
# Liveness (act_runner metrics /healthz, per host)
ssh dbc   'curl -s localhost:9101/healthz'
ssh spark 'curl -s localhost:9101/healthz'
ssh evo   'curl -s localhost:9101/healthz'          # WSL

# Restart
ssh dbc   'launchctl kickstart -k gui/$(id -u)/ai.hanzo.git-runner'
ssh spark 'sudo systemctl restart git-runner'
ssh evo   'sudo systemctl restart git-runner'        # WSL
# evo Windows: Stop-ScheduledTask HanzoGitRunner; Start-ScheduledTask HanzoGitRunner

# Registered runners (Site Admin → Actions → Runners), or in-cluster:
kubectl -n hanzo get pods -l app=git-runner
```

## Anti-patterns / don'ts

- **DON'T** reinstall `arcd`. It is retired; `act_runner` is the ONE runner.
- **DON'T** invent a new `runs-on` label — author the canonical compound
  `<org>-<os>-<arch>`; if a capability is missing, add it to the union here
  and to the host config, in one place.
- **DON'T** register a runner with ad-hoc `--labels`. Labels live in
  `infra/runners/<host>/config.yaml`; `register.sh` reads them from there.
- **DON'T** put codesigning secrets in a repo. Org secrets → `secrets: inherit`.
- **DON'T** advertise `h100` on spark — it is Blackwell. H100 is a separate
  luxcpp host.
- **DON'T** run the dbc runner headless — Metal needs the Aqua GUI session.
