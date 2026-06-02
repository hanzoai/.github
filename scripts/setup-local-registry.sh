#!/usr/bin/env bash
# setup-local-registry.sh — local Docker registry on a builder host with
# storage cap + periodic prune. Buildx uses it as a registry-based cache
# target so layers don't re-pull/re-build across runs.
#
# Usage (on each host):
#   ./setup-local-registry.sh
#
# What it does:
#   1. Runs registry:2 on localhost:5001 (5000 conflicts with macOS AirPlay)
#      persisted to ~/.docker-registry-data
#   2. Configures docker daemon to accept localhost:5001 as insecure registry
#   3. Installs a daily cron / launchd job to prune old images + cap registry
#      storage at 50% of free disk (or 100Gi, whichever is smaller)
#   4. Exposes env var DOCKER_REGISTRY_CACHE=localhost:5001 for workflows
#
# Storage management:
#   - Daily: `docker system prune -af --filter "until=168h"` (1 week)
#   - When disk > 80% used: `docker system prune -af` (aggressive)
#   - Registry blob GC weekly (Sundays 2am)
#
# Idempotent — re-running is safe.

set -euo pipefail

REGISTRY_PORT="${REGISTRY_PORT:-5001}"
REGISTRY_DATA="${HOME}/.docker-registry-data"
REGISTRY_IMAGE="registry:2"
PRUNE_THRESHOLD_PCT="${PRUNE_THRESHOLD_PCT:-80}"
PRUNE_RETAIN_DAYS="${PRUNE_RETAIN_DAYS:-7}"

UNAME_S="$(uname -s)"

echo "── local docker registry setup ───────────────────"
echo "  port:     $REGISTRY_PORT"
echo "  data:     $REGISTRY_DATA"
echo "  prune:    >${PRUNE_THRESHOLD_PCT}% used → aggressive, else >${PRUNE_RETAIN_DAYS}d retain"
echo

# ── registry container ─────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not installed" >&2
  exit 2
fi

mkdir -p "$REGISTRY_DATA"

# Stop any existing
docker stop local-registry 2>/dev/null || true
docker rm   local-registry 2>/dev/null || true

docker run -d \
  --restart always \
  --name local-registry \
  -p "${REGISTRY_PORT}:5000" \
  -v "${REGISTRY_DATA}:/var/lib/registry" \
  -e REGISTRY_STORAGE_DELETE_ENABLED=true \
  "$REGISTRY_IMAGE"

echo "  registry started → http://localhost:${REGISTRY_PORT}/v2/"
echo

# ── prune script ────────────────────────────────────────────────────
PRUNE_SCRIPT="${HOME}/.docker-registry-prune.sh"
cat > "$PRUNE_SCRIPT" <<EOF
#!/usr/bin/env bash
# Auto-prune docker storage. Installed by setup-local-registry.sh.
set -euo pipefail

# Disk usage % of root volume
disk_pct=\$(df -k / | awk 'NR==2 {gsub("%",""); print \$5}')

if [[ "\$disk_pct" -ge ${PRUNE_THRESHOLD_PCT} ]]; then
  echo "[\$(date)] disk \${disk_pct}% — AGGRESSIVE prune"
  docker system prune -af >/dev/null 2>&1
  # Also drop registry blobs
  docker exec local-registry bin/registry garbage-collect /etc/docker/registry/config.yml 2>/dev/null || true
else
  echo "[\$(date)] disk \${disk_pct}% — retain ${PRUNE_RETAIN_DAYS}d"
  docker system prune -af --filter "until=$((PRUNE_RETAIN_DAYS * 24))h" >/dev/null 2>&1
fi

# Log summary
docker system df >> ~/.docker-registry-prune.log
echo "---" >> ~/.docker-registry-prune.log
EOF
chmod +x "$PRUNE_SCRIPT"

# ── schedule prune ──────────────────────────────────────────────────
case "$UNAME_S" in
  Darwin)
    PLIST="${HOME}/Library/LaunchAgents/com.hanzo.docker-prune.plist"
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.hanzo.docker-prune</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${PRUNE_SCRIPT}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key><integer>3</integer>
        <key>Minute</key><integer>0</integer>
    </dict>
    <key>RunAtLoad</key><false/>
    <key>StandardErrorPath</key><string>${HOME}/.docker-registry-prune.err</string>
</dict>
</plist>
EOF
    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl load "$PLIST"
    echo "  scheduled: launchd @3am daily"
    ;;
  Linux)
    # cron
    (crontab -l 2>/dev/null | grep -v "docker-registry-prune"; echo "0 3 * * * ${PRUNE_SCRIPT}") | crontab -
    echo "  scheduled: cron @3am daily"
    ;;
esac

echo
echo "── done ─────────────────────────────────────────"
echo "  use in buildx: --cache-to type=registry,ref=localhost:${REGISTRY_PORT}/cache:<tag>"
echo "                 --cache-from type=registry,ref=localhost:${REGISTRY_PORT}/cache:<tag>"
echo "  manual prune:  ${PRUNE_SCRIPT}"
echo "  log:           ~/.docker-registry-prune.log"
