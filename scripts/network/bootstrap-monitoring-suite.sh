#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/install-vps-health-watch.sh"
"$SCRIPT_DIR/install-vps-weekly-slo-report.sh"

echo "Monitoring suite bootstrap completed."
