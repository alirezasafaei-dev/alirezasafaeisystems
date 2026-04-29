#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$ROOT_DIR/vps-install-redis-monitoring.sh"
"$ROOT_DIR/vps-install-daily-platform-report.sh"
"$ROOT_DIR/vps-install-arvan-edge-probe.sh"

echo
echo "Running quick status check..."
"$ROOT_DIR/vps-monitoring-status.sh"
