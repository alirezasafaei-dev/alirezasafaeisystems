#!/usr/bin/env bash
# Probe PersianToolbox app layer on public VPS via SSH (read-only).
set -euo pipefail
SSH_HOST="${PUBLIC_VPS_SSH:-ubuntu@193.93.169.32}"
SSH_KEY="${PUBLIC_VPS_SSH_KEY:-/home/dev13/.ssh/id_ed25519}"
TIMEOUT="${HTTP_TIMEOUT_SECS:-8}"
SSH=(ssh -o BatchMode=yes -o ConnectTimeout=10 -i "$SSH_KEY" "$SSH_HOST")

log(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# Detect active upstream port from nginx conf, fallback 3003
PORT=$("${SSH[@]}" "grep -oE '127\\.0\\.0\\.1:[0-9]+' /etc/nginx/conf.d/persiantoolbox-upstream.conf 2>/dev/null | head -1 | cut -d: -f2" || true)
PORT=${PORT:-3003}
log "probing public VPS app layer port=$PORT"

OUT=$("${SSH[@]}" "curl -sS -m $TIMEOUT -o /dev/null -w '%{http_code}' http://127.0.0.1:${PORT}/api/ready" || echo 000)
log "ready HTTP $OUT"
[[ "$OUT" =~ ^2 ]] || { log "ERROR ready failed"; exit 1; }
OUT2=$("${SSH[@]}" "curl -sS -m $TIMEOUT -o /dev/null -w '%{http_code}' http://127.0.0.1:${PORT}/api/health" || echo 000)
log "health HTTP $OUT2"
[[ "$OUT2" =~ ^2 ]] || { log "ERROR health failed"; exit 1; }
log "OK public VPS app-layer"
