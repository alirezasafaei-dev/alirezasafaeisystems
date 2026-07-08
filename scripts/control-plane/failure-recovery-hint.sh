#!/usr/bin/env bash
# Print recovery hints from last health JSON + common failure modes (read-only).
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
H="$ROOT/control-plane/health/last-health.json"
echo "========================================"
echo "  CONTROL PLANE FAILURE RECOVERY HINTS"
echo "========================================"
if [[ -f "$H" ]]; then
  echo "last_health:"
  cat "$H"
else
  echo "no last-health.json — run automation-health-check.sh"
fi
echo
echo "Common recoveries (safe):"
echo "1. git pull --ff-only origin main"
echo "2. bash scripts/ops/automation-health-check.sh"
echo "3. Restart Hermes/OpenClaw only if owner wants (document first)"
echo "4. IRAN app down: check deploy-status + logs; redeploy needs phrase"
echo "5. Queue stuck in_progress: inspect queue.json updated_at; complete or re-approve"
echo "Never: docker rm -f unknown; force-push main; expose secrets"
