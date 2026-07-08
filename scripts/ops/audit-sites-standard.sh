#!/usr/bin/env bash
# Audit registry sites for project.yaml + README readiness.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
REG="$ROOT/deploy/registry.tsv"
echo "========================================"
echo "  SITES STANDARD AUDIT"
echo "========================================"
missing=0
while IFS=$'\t' read -r site_id rest; do
  [[ "$site_id" == "site_id" || "$site_id" == \#* || -z "$site_id" ]] && continue
  # resolve path
  repo_path=$(awk -F'\t' -v s="$site_id" '$1==s{print $5}' "$REG")
  path="$ROOT/$repo_path"
  if [[ "$site_id" == "alirezasafaeisystems" ]]; then
    path="$ROOT"
  fi
  status="OK"
  notes=()
  if [[ ! -d "$path" && "$site_id" != "alirezasafaeisystems" ]]; then
    status="MISSING_SRC"
    missing=$((missing + 1))
  else
    if [[ ! -f "$path/project.yaml" ]]; then
      status="NO_PROJECT_YAML"
      missing=$((missing + 1))
    fi
    if [[ ! -f "$path/README.md" && ! -f "$path/readme.md" ]]; then
      notes+=("no_readme")
    fi
  fi
  echo "$site_id	$status	$path	${notes[*]:-}"
done < "$REG"
echo "========================================"
echo "gaps=$missing"
[[ "$missing" -eq 0 ]] && exit 0 || exit 0  # report only; non-blocking
