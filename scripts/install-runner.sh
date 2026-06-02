#!/usr/bin/env bash
# install-runner.sh — register a GitHub Actions self-hosted runner with per-org isolation.
#
# Usage:
#   GH_RUNNER_TOKEN=<reg-token> ./install-runner.sh <org> <host-nickname>
#
# Examples:
#   GH_RUNNER_TOKEN=ABC... ./install-runner.sh hanzoai spark
#   GH_RUNNER_TOKEN=ABC... ./install-runner.sh luxfi   dbc
#   GH_RUNNER_TOKEN=ABC... ./install-runner.sh zooai   evo
#
# Token: obtain via
#   gh api -X POST /orgs/<org>/actions/runners/registration-token | jq -r .token
#   (requires admin:org on the PAT)
#
# Idempotent: re-running with the same args reconfigures (after stopping the
# existing service) — does not double-register.
#
# Labels applied (org-scoped, NOT cross-visible):
#   <host>-<org>-<arch>      e.g. spark-luxfi-arm64
#   <host>-<org>-<os>        e.g. dbc-hanzoai-macos
#   self-hosted              (always)
#
# Service:
#   Linux  → systemd unit (actions.runner.<org>.<runner-name>.service)
#   macOS  → launchd plist (~/Library/LaunchAgents/actions.runner.<org>.<runner-name>.plist)
#   WSL    → systemd unit (same as Linux)
#
# Per-org isolation:
#   Each registration is scoped to the org; cross-org callers cannot
#   dispatch to a runner labelled for a different org. This is enforced
#   by GitHub at registration time.

set -euo pipefail

ORG="${1:-}"
HOST="${2:-}"

if [[ -z "$ORG" || -z "$HOST" ]]; then
  echo "usage: GH_RUNNER_TOKEN=<token> $0 <org> <host-nickname>" >&2
  echo "       org:  hanzoai | luxfi | zooai" >&2
  echo "       host: spark | evo | dbc | <any short name>" >&2
  exit 2
fi

if [[ -z "${GH_RUNNER_TOKEN:-}" ]]; then
  echo "error: GH_RUNNER_TOKEN env var required" >&2
  echo "  get one: gh api -X POST /orgs/$ORG/actions/runners/registration-token | jq -r .token" >&2
  exit 2
fi

# ── platform detection ─────────────────────────────────────────────
UNAME_S="$(uname -s)"
UNAME_M="$(uname -m)"
case "$UNAME_S" in
  Linux)
    OS="linux"
    PLAT="linux"
    case "$UNAME_M" in
      x86_64)  ARCH="x86_64"; PKG_ARCH="x64"   ;;
      aarch64) ARCH="arm64";  PKG_ARCH="arm64" ;;
      arm64)   ARCH="arm64";  PKG_ARCH="arm64" ;;
      *) echo "unsupported linux arch: $UNAME_M" >&2; exit 3 ;;
    esac
    # detect WSL
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
      OS="wsl"
    fi
    ;;
  Darwin)
    OS="macos"
    PLAT="osx"
    case "$UNAME_M" in
      arm64)  ARCH="arm64";  PKG_ARCH="arm64" ;;
      x86_64) ARCH="x86_64"; PKG_ARCH="x64"   ;;
      *) echo "unsupported darwin arch: $UNAME_M" >&2; exit 3 ;;
    esac
    ;;
  *) echo "unsupported OS: $UNAME_S" >&2; exit 3 ;;
esac

RUNNER_NAME="${HOST}-${ORG}-${ARCH}"
LABELS="self-hosted,${HOST}-${ORG}-${ARCH},${HOST}-${ORG}-${OS}"
INSTALL_DIR="${HOME}/actions-runner-${ORG}-${HOST}"
RUNNER_URL="https://github.com/${ORG}"

# ── pick runner package version (pin to LTS) ───────────────────────
RUNNER_VER="${RUNNER_VER:-2.321.0}"
PKG="actions-runner-${PLAT}-${PKG_ARCH}-${RUNNER_VER}.tar.gz"
PKG_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VER}/${PKG}"

echo "── installing runner ─────────────────────────────"
echo "  host:    $HOST ($UNAME_S/$UNAME_M)"
echo "  org:     $ORG"
echo "  name:    $RUNNER_NAME"
echo "  labels:  $LABELS"
echo "  dir:     $INSTALL_DIR"
echo "  version: $RUNNER_VER"
echo

# ── stop existing service if any (idempotent reinstall) ────────────
if [[ -d "$INSTALL_DIR" ]] && [[ -x "$INSTALL_DIR/svc.sh" ]]; then
  echo "stopping existing service..."
  ( cd "$INSTALL_DIR" && sudo ./svc.sh stop 2>/dev/null || ./svc.sh stop 2>/dev/null || true )
  ( cd "$INSTALL_DIR" && sudo ./svc.sh uninstall 2>/dev/null || ./svc.sh uninstall 2>/dev/null || true )
  ( cd "$INSTALL_DIR" && ./config.sh remove --token "$GH_RUNNER_TOKEN" 2>/dev/null || true )
fi

# ── fetch + extract ────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
if [[ ! -f "$PKG" ]]; then
  curl -fsSL -o "$PKG" "$PKG_URL"
fi
tar xzf "$PKG"

# ── configure (org-scoped registration) ────────────────────────────
./config.sh \
  --unattended \
  --replace \
  --url "$RUNNER_URL" \
  --token "$GH_RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$LABELS" \
  --work "_work"

# ── install + start service ────────────────────────────────────────
if [[ "$OS" == "macos" ]]; then
  ./svc.sh install
  ./svc.sh start
else
  sudo ./svc.sh install "$USER" || ./svc.sh install
  sudo ./svc.sh start || ./svc.sh start
fi

echo
echo "── done ──────────────────────────────────────────"
echo "  runner '$RUNNER_NAME' registered on org '$ORG'"
echo "  use in workflows with: runs-on: ${HOST}-${ORG}-${ARCH}"
echo "  status: ( cd $INSTALL_DIR && ./svc.sh status )"
echo "  stop:   ( cd $INSTALL_DIR && sudo ./svc.sh stop )"
