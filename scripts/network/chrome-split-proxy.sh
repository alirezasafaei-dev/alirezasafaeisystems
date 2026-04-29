#!/usr/bin/env bash
set -euo pipefail

PROXY_SERVER="${PROXY_SERVER:-socks5://127.0.0.1:10808}"
PROFILE_DIR="${PROFILE_DIR:-$HOME/.config/google-chrome-asdev-split}"

BYPASS_LIST="localhost;127.0.0.1;::1;*.alirezasafaeisystems.ir;alirezasafaeisystems.ir;*.persiantoolbox.ir;persiantoolbox.ir"

mkdir -p "$PROFILE_DIR"

exec google-chrome \
  --user-data-dir="$PROFILE_DIR" \
  --proxy-server="$PROXY_SERVER" \
  --proxy-bypass-list="$BYPASS_LIST" \
  "$@"
