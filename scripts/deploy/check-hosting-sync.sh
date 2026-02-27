#!/usr/bin/env bash
set -euo pipefail

STRICT=false
ROOT_DIR="/var/www"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--strict] [--root-dir <path>]

Checks multi-site port allocation and storage/cache layout for shared VPS hosting.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=true
      shift
      ;;
    --root-dir)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[audit] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

APPS=(
  "persian-tools:3000:3001:${ROOT_DIR}/persian-tools:persiantoolbox.ir:staging.persiantoolbox.ir"
  "alirezasafaeisystems:3002:3003:${ROOT_DIR}/my-portfolio:alirezasafaeisystems.ir:staging.alirezasafaeisystems.ir"
)

status=0
declare -A seen_ports

echo "[audit] port registry"
for entry in "${APPS[@]}"; do
  IFS=':' read -r slug prod_port stag_port base_dir prod_domain stag_domain <<<"$entry"
  echo "  - ${slug}: production=${prod_port} (${prod_domain}), staging=${stag_port} (${stag_domain})"

  for port in "$prod_port" "$stag_port"; do
    if [[ -n "${seen_ports[$port]:-}" ]]; then
      echo "[audit] ERROR duplicate port ${port}: ${slug} vs ${seen_ports[$port]}" >&2
      status=1
    else
      seen_ports[$port]="$slug"
    fi
  done

  if [[ -d "$base_dir" ]]; then
    echo "[audit] storage ${slug}"
    du -sh "$base_dir"/releases "$base_dir"/shared/logs "$base_dir"/shared/env 2>/dev/null || true
    if [[ -d "$base_dir/releases" ]]; then
      cache_count=$(find "$base_dir/releases" -type d -name cache -path '*/.next/cache' 2>/dev/null | wc -l | tr -d ' ')
    else
      cache_count=0
    fi
    echo "  .next cache dirs: ${cache_count}"
  else
    echo "[audit] WARN missing base dir for ${slug}: ${base_dir}" >&2
    if [[ "$STRICT" == "true" ]]; then
      status=1
    fi
  fi
done

if command -v ss >/dev/null 2>&1; then
  echo "[audit] listener snapshot"
  ss -ltnp | awk 'NR==1 || /:3000|:3001|:3002|:3003/' || true
else
  echo "[audit] WARN ss command not found"
fi

if [[ "$status" -ne 0 ]]; then
  echo "[audit] FAILED" >&2
  exit "$status"
fi

echo "[audit] OK"
