#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Generate Quarantine Plan from Inventory
# ============================================================================
# Reads inventory JSON and produces:
#   1. An allowlist of confirmed non-critical sites (safe to quarantine)
#   2. A markdown quarantine plan
#
# Sites classified as CRITICAL_SITE or UNKNOWN are NEVER included in the allowlist.
#
# Usage: ./generate-quarantine-plan.sh <inventory.json> [--output-dir <dir>]
# ============================================================================

CRITICAL_SITES=("persiantoolbox.ir" "persiantoolbox")

# ============================================================================
# HELPERS
# ============================================================================

log() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" >&2
}

log_error() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ERROR: $1" >&2
}

is_critical() {
    local site="$1"
    for crit in "${CRITICAL_SITES[@]}"; do
        if [[ "$site" == "$crit" ]]; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

INVENTORY_FILE=""
OUTPUT_DIR="/tmp/quarantine-plan-$(date -u +%Y%m%dT%H%M%SZ)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            if [[ -z "$INVENTORY_FILE" ]]; then
                INVENTORY_FILE="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$INVENTORY_FILE" ]] || [[ ! -f "$INVENTORY_FILE" ]]; then
    log_error "Usage: $0 <inventory.json> [--output-dir <dir>]"
    log_error "Provide a valid inventory JSON file"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required but not installed"
    exit 1
fi

# ============================================================================
# PARSE INVENTORY
# ============================================================================

log "Reading inventory from: $INVENTORY_FILE"

APP_COUNT=$(jq '.app_directories | length' "$INVENTORY_FILE" 2>/dev/null || echo "0")
PM2_COUNT=$(jq '.pm2_processes | length' "$INVENTORY_FILE" 2>/dev/null || echo "0")
NGINX_COUNT=$(jq '.nginx_configs | length' "$INVENTORY_FILE" 2>/dev/null || echo "0")

log "Found $APP_COUNT app directories, $PM2_COUNT PM2 processes, $NGINX_COUNT nginx configs"

# ============================================================================
# CLASSIFY SITES
# ============================================================================

SITES_CRITICAL=()
SITES_CANDIDATE=()
SITES_UNKNOWN=()

for i in $(seq 0 $((APP_COUNT - 1))); do
    SITE_NAME=$(jq -r ".app_directories[$i].name" "$INVENTORY_FILE")
    SITE_PATH=$(jq -r ".app_directories[$i].path" "$INVENTORY_FILE")
    SITE_SIZE=$(jq -r ".app_directories[$i].size" "$INVENTORY_FILE")

    if [[ -z "$SITE_NAME" ]] || [[ "$SITE_NAME" == "null" ]]; then
        continue
    fi

    if is_critical "$SITE_NAME"; then
        SITES_CRITICAL+=("$SITE_NAME")
        log "  CRITICAL: $SITE_NAME (excluded from quarantine)"
        continue
    fi

    HAS_PM2=$(jq -r --arg name "$SITE_NAME" '.pm2_processes[] | select(.name == $name) | .name' "$INVENTORY_FILE" 2>/dev/null | head -1)
    HAS_NGINX=$(jq -r --arg name "$SITE_NAME" '.nginx_configs[] | select(.server_names | test($name)) | .file' "$INVENTORY_FILE" 2>/dev/null | head -1)

    if [[ -n "$HAS_PM2" ]] || [[ -n "$HAS_NGINX" ]]; then
        SITES_CANDIDATE+=("$SITE_NAME")
        log "  CANDIDATE: $SITE_NAME (has PM2=$([ -n "$HAS_PM2" ] && echo yes || echo no), nginx=$([ -n "$HAS_NGINX" ] && echo yes || echo no))"
    else
        SITES_UNKNOWN+=("$SITE_NAME")
        log "  UNKNOWN: $SITE_NAME (no PM2 process or nginx config found — refusing to classify)"
    fi
done

# ============================================================================
# GENERATE ALLOWLIST
# ============================================================================

mkdir -p "$OUTPUT_DIR"

ALLOWLIST_FILE="${OUTPUT_DIR}/quarantine-allowlist.txt"
PLAN_FILE="${OUTPUT_DIR}/quarantine-plan.md"

log "Writing allowlist to: $ALLOWLIST_FILE"

{
    echo "# Quarantine Allowlist"
    echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "# Only sites listed here may be quarantined by quarantine-non-critical.sh"
    echo "#"
    echo "# CRITICAL sites (never quarantine): ${SITES_CRITICAL[*]:-none}"
    echo "# UNKNOWN sites (refused — unclear role): ${SITES_UNKNOWN[*]:-none}"
    echo "#"
    for site in "${SITES_CANDIDATE[@]}"; do
        echo "$site"
    done
} > "$ALLOWLIST_FILE"

# ============================================================================
# GENERATE QUARANTINE PLAN MARKDOWN
# ============================================================================

log "Writing quarantine plan to: $PLAN_FILE"

cat > "$PLAN_FILE" <<PLANEOF
# IRAN_PROD Non-Critical Site Quarantine Plan

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Source Inventory:** $INVENTORY_FILE
**Classification:** INTERNAL - PRODUCTION OPERATIONS

---

## Site Classification

### CRITICAL Sites (Excluded from Quarantine)

| Site | Reason |
|------|--------|
PLANEOF

for site in "${SITES_CRITICAL[@]}"; do
    echo "| $site | Marked CRITICAL — never quarantine |" >> "$PLAN_FILE"
done
if [[ ${#SITES_CRITICAL[@]} -eq 0 ]]; then
    echo "| (none) | — |" >> "$PLAN_FILE"
fi

cat >> "$PLAN_FILE" <<PLANEOF

### Safe Quarantine Candidates

| Site | PM2 Process | Nginx Config | App Size | Recommendation |
|------|-------------|--------------|----------|----------------|
PLANEOF

for site in "${SITES_CANDIDATE[@]}"; do
    HAS_PM2=$(jq -r --arg name "$site" '.pm2_processes[] | select(.name == $name) | .name' "$INVENTORY_FILE" 2>/dev/null | head -1)
    HAS_NGINX=$(jq -r --arg name "$site" '.nginx_configs[] | select(.server_names | test($name)) | .file' "$INVENTORY_FILE" 2>/dev/null | head -1)
    SITE_SIZE=$(jq -r --arg name "$site" '.app_directories[] | select(.name == $name) | .size' "$INVENTORY_FILE" 2>/dev/null | head -1)
    echo "| $site | $([ -n "$HAS_PM2" ] && echo "Yes" || echo "No") | $([ -n "$HAS_NGINX" ] && echo "Yes" || echo "No") | ${SITE_SIZE:-unknown} | Quarantine |" >> "$PLAN_FILE"
done
if [[ ${#SITES_CANDIDATE[@]} -eq 0 ]]; then
    echo "| (none) | — | — | — | — |" >> "$PLAN_FILE"
fi

cat >> "$PLAN_FILE" <<PLANEOF

### Unknown Sites (Refused — Not Included in Allowlist)

These sites exist on disk but have no matching PM2 process or nginx config.
The quarantine script **will refuse** to operate on them until they are manually classified.

| Site | Path | Size | Status |
|------|------|------|--------|
PLANEOF

for site in "${SITES_UNKNOWN[@]}"; do
    SITE_PATH=$(jq -r --arg name "$site" '.app_directories[] | select(.name == $name) | .path' "$INVENTORY_FILE" 2>/dev/null | head -1)
    SITE_SIZE=$(jq -r --arg name "$site" '.app_directories[] | select(.name == $name) | .size' "$INVENTORY_FILE" 2>/dev/null | head -1)
    echo "| $site | ${SITE_PATH:-unknown} | ${SITE_SIZE:-unknown} | **BLOCKED** |" >> "$PLAN_FILE"
done
if [[ ${#SITES_UNKNOWN[@]} -eq 0 ]]; then
    echo "| (none) | — | — | — |" >> "$PLAN_FILE"
fi

cat >> "$PLAN_FILE" <<PLANEOF

---

## Workflow

1. Run inventory: \`./scripts/ops/iran-prod-inventory.sh APPROVE_IRAN_PROD_SITE_INVENTORY\`
2. Generate plan: \`./scripts/ops/generate-quarantine-plan.sh /path/to/inventory.json\`
3. Review allowlist at \`quarantine-allowlist.txt\`
4. Quarantine (dry-run first): \`./scripts/ops/quarantine-non-critical.sh --dry-run APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL <site>\`
5. Quarantine (live): \`./scripts/ops/quarantine-non-critical.sh APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL <site>\`

## Safety Rules

- **CRITICAL sites** are never quarantined — the script refuses them
- **Unknown sites** (no PM2, no nginx config) are never quarantined — the script refuses them
- **Dry-run is the default** — must pass explicit approval to go live
- **No permanent deletion** — quarantine only, separate procedure required
- **No automatic nginx reload** — operator must reload manually after review
- **No automatic PM2 stop** — only if plan explicitly confirms the process is non-critical
- **Recovery manifest** is always created for every quarantine action

---

**Classification:** Handle according to information security policies.
PLANEOF

log "Quarantine plan generated successfully"
log "  Allowlist: $ALLOWLIST_FILE"
log "  Plan:      $PLAN_FILE"
log "  Candidates: ${#SITES_CANDIDATE[@]} site(s)"
log "  Critical:   ${#SITES_CRITICAL[@]} site(s)"
log "  Unknown:    ${#SITES_UNKNOWN[@]} site(s) — blocked from quarantine"
