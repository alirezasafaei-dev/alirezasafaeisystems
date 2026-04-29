#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$ROOT_DIR"

echo "[1/3] Edge route diagnosis"
./scripts/network/diagnose-edge-route.sh

echo "[2/3] GSC preflight"
bash ../seo/gsc/gsc-preflight.sh || true

echo "[3/3] Network smoke (chromium, proxy matrix if env exists)"
NETWORK_SMOKE_BROWSERS=chromium NETWORK_SMOKE_INCLUDE_PROXY=true node scripts/network-smoke-matrix.mjs || true

echo "Ops suite run completed."
