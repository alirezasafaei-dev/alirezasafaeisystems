#!/bin/bash
# offline-external-scan.sh - Detect runtime outbound requests
# This script scans for external URLs in source code, configs, and public assets

set -euo pipefail

echo "=========================================="
echo "🔒 External Dependencies Scan"
echo "=========================================="

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

FOUND_EXTERNAL=0
WARNINGS=()

# Scanner contract: ripgrep is required for the repository/build scans below.
# Resolve it before defining the wrapper so a missing or broken scanner can
# never be interpreted as a clean scan by legacy `|| true` call sites.
RG_BIN="${EXTERNAL_SCAN_RG_BIN:-rg}"
if ! RG_PATH="$(command -v "$RG_BIN" 2>/dev/null)" || [ -z "$RG_PATH" ]; then
    echo -e "${RED}❌ External scan unavailable: required scanner '$RG_BIN' was not found.${NC}" >&2
    exit 2
fi

RG_ERROR_FILE="$(mktemp)"
trap 'rm -f "$RG_ERROR_FILE"' EXIT

rg() {
    local status
    set +e
    "$RG_PATH" "$@"
    status=$?
    set -e

    # ripgrep: 0=match, 1=no match, >1=runtime/scanner error.
    if [ "$status" -gt 1 ]; then
        printf '%s\n' "$status" >> "$RG_ERROR_FILE"
        echo "External scan scanner error: ripgrep exited with status $status." >&2
    fi
    return "$status"
}

# Allowed exceptions (documented and intentional)
ALLOWLIST_FILE="${EXTERNAL_SCAN_ALLOWLIST_FILE:-scripts/external-scan-allowlist.txt}"
ALLOWED_EXTERNALS=()

# Directories to skip from repository-wide scans
SCAN_EXCLUDES=(
    ".git"
    "node_modules"
    ".next"
    "dist"
    "coverage"
    "_ops/external"
)

build_exclude_args() {
    local args=()
    for path in "${SCAN_EXCLUDES[@]}"; do
        args+=(--glob "!${path}/**")
    done
    printf '%s\n' "${args[@]}"
}

load_allowlist() {
    if [ -f "$ALLOWLIST_FILE" ]; then
        while IFS= read -r line; do
            line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [ -z "$line" ] && continue
            [[ "$line" =~ ^# ]] && continue
            ALLOWED_EXTERNALS+=("$line")
        done < "$ALLOWLIST_FILE"
    fi

    if [ -n "${EXTERNAL_SCAN_ALLOWLIST:-}" ]; then
        IFS=',' read -ra extra_allowlist <<< "${EXTERNAL_SCAN_ALLOWLIST}"
        for item in "${extra_allowlist[@]}"; do
            item="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [ -z "$item" ] && continue
            ALLOWED_EXTERNALS+=("$item")
        done
    fi
}

is_allowed_external() {
    local line="$1"
    for allowed in "${ALLOWED_EXTERNALS[@]}"; do
        if [[ "$line" == *"$allowed"* ]]; then
            return 0
        fi
    done
    return 1
}

print_filtered_matches() {
    local matches="$1"
    local filtered=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if ! is_allowed_external "$line"; then
            filtered+="${line}"$'\n'
        fi
    done <<< "$matches"
    printf '%s' "$filtered"
}

echo ""
echo "📁 Scanning source files for external URLs..."
echo "------------------------------------------"
load_allowlist

# Scan for runtime outbound requests (high signal, low false positives)
if [ -d "src" ]; then
    echo "Checking runtime request patterns in src/..."
    RUNTIME_FETCH=$(rg -n "fetch\\s*\\(\\s*['\\\"]https?://" src --glob "*.{ts,tsx,js,jsx}" || true)
    RUNTIME_AXIOS=$(rg -n "axios\\.(get|post|put|patch|delete)\\s*\\(\\s*['\\\"]https?://" src --glob "*.{ts,tsx,js,jsx}" || true)
    RUNTIME_WS=$(rg -n "(WebSocket|EventSource)\\s*\\(\\s*['\\\"](wss?|https?)://" src --glob "*.{ts,tsx,js,jsx}" || true)

    if [ -n "$RUNTIME_FETCH" ] || [ -n "$RUNTIME_AXIOS" ] || [ -n "$RUNTIME_WS" ]; then
        echo -e "${RED}❌ Found runtime external requests in src/:${NC}"
        [ -n "$RUNTIME_FETCH" ] && echo "$RUNTIME_FETCH"
        [ -n "$RUNTIME_AXIOS" ] && echo "$RUNTIME_AXIOS"
        [ -n "$RUNTIME_WS" ] && echo "$RUNTIME_WS"
        FOUND_EXTERNAL=1
    else
        echo -e "${GREEN}✓ No runtime external requests found in src/${NC}"
    fi
fi

# Scan built runtime output from .next (required for deploy confidence)
echo ""
echo "🏗️ Scanning build output (.next) for runtime externals..."
echo "------------------------------------------"

if [ ! -d ".next" ]; then
    echo -e "${RED}❌ Build output not found: .next${NC}"
    echo "Run 'pnpm run build' before running this scan."
    FOUND_EXTERNAL=1
else
    BUILD_RUNTIME_FETCH=$(rg -n "fetch\\s*\\(\\s*['\\\"]https?://" .next --glob "*.{js,mjs,cjs}" || true)
    BUILD_RUNTIME_AXIOS=$(rg -n "axios\\.(get|post|put|patch|delete)\\s*\\(\\s*['\\\"]https?://" .next --glob "*.{js,mjs,cjs}" || true)
    BUILD_RUNTIME_WS=$(rg -n "(WebSocket|EventSource)\\s*\\(\\s*['\\\"](wss?|https?)://" .next --glob "*.{js,mjs,cjs}" || true)

    FILTERED_BUILD_RUNTIME_FETCH=$(print_filtered_matches "$BUILD_RUNTIME_FETCH")
    FILTERED_BUILD_RUNTIME_AXIOS=$(print_filtered_matches "$BUILD_RUNTIME_AXIOS")
    FILTERED_BUILD_RUNTIME_WS=$(print_filtered_matches "$BUILD_RUNTIME_WS")

    if [ -n "$FILTERED_BUILD_RUNTIME_FETCH" ] || [ -n "$FILTERED_BUILD_RUNTIME_AXIOS" ] || [ -n "$FILTERED_BUILD_RUNTIME_WS" ]; then
        echo -e "${RED}❌ Found runtime external requests in .next:${NC}"
        [ -n "$FILTERED_BUILD_RUNTIME_FETCH" ] && echo "$FILTERED_BUILD_RUNTIME_FETCH"
        [ -n "$FILTERED_BUILD_RUNTIME_AXIOS" ] && echo "$FILTERED_BUILD_RUNTIME_AXIOS"
        [ -n "$FILTERED_BUILD_RUNTIME_WS" ] && echo "$FILTERED_BUILD_RUNTIME_WS"
        FOUND_EXTERNAL=1
    else
        echo -e "${GREEN}✓ No runtime external requests found in .next${NC}"
    fi
fi

# Scan public text files only (-I ignores binary files)
if [ -d "public" ]; then
    echo "Checking public/ text assets for external URLs..."
    PUB_EXTERNALS=$(grep -rInI "https\\?://" public/ --exclude="*.png" --exclude="*.jpg" --exclude="*.jpeg" --exclude="*.webp" --exclude="*.ico" --exclude="*.woff" --exclude="*.woff2" --exclude="*.ttf" --exclude="*.otf" 2>/dev/null || true)
    FILTERED_PUB_EXTERNALS=$(print_filtered_matches "$PUB_EXTERNALS")
    if [ -n "$FILTERED_PUB_EXTERNALS" ]; then
        echo -e "${YELLOW}⚠ Found external URLs in public/ text assets:${NC}"
        echo "$FILTERED_PUB_EXTERNALS"
        WARNINGS+=("External URLs in public text assets")
    fi
fi

# Scan config files
echo ""
echo "🔧 Scanning configuration files..."
echo "------------------------------------------"

CONFIG_FILES=("next.config.ts" "next.config.js" "tailwind.config.ts" "tailwind.config.js")
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        CONFIG_EXTERNALS=$(grep -n "https\?://" "$file" 2>/dev/null || true)
        if [ -n "$CONFIG_EXTERNALS" ]; then
            echo -e "${YELLOW}⚠ Found external URLs in $file:${NC}"
            echo "$CONFIG_EXTERNALS"
            FOUND_EXTERNAL=1
        fi
    fi
done

# Check for placeholder production domain
echo ""
echo "🏷️ Checking for placeholder domain..."
echo "------------------------------------------"

PLACEHOLDER_REFS=$(rg -n "yourportfolio\\.com|portfolio\\.example\\.com" src \
    --glob "*.{ts,tsx,js,jsx}" \
    --glob "!src/**/__tests__/**" || true)
if [ -n "$PLACEHOLDER_REFS" ]; then
    echo -e "${RED}❌ Found placeholder domain references:${NC}"
    echo "$PLACEHOLDER_REFS"
    FOUND_EXTERNAL=1
fi

# Check for CDN references
echo ""
echo "🌐 Checking for CDN references..."
echo "------------------------------------------"

CDN_PATTERNS=("googleapis.com" "cdnjs.cloudflare.com" "unpkg.com" "jsdelivr.net" "fonts.googleapis.com")
mapfile -t RG_EXCLUDES < <(build_exclude_args)
for pattern in "${CDN_PATTERNS[@]}"; do
    CDN_REFS=$(rg -n "$pattern" . \
        --glob "*.html" \
        --glob "*.tsx" \
        --glob "*.ts" \
        --glob "*.js" \
        --glob "*.css" \
        "${RG_EXCLUDES[@]}" || true)
    FILTERED_CDN_REFS=$(print_filtered_matches "$CDN_REFS")
    if [ -n "$FILTERED_CDN_REFS" ]; then
        echo -e "${RED}❌ Found CDN reference ($pattern):${NC}"
        echo "$FILTERED_CDN_REFS"
        FOUND_EXTERNAL=1
    fi
done

if [ -d ".next" ]; then
    for pattern in "${CDN_PATTERNS[@]}"; do
        BUILD_CDN_REFS=$(rg -n "$pattern" .next \
            --glob "*.js" \
            --glob "*.mjs" \
            --glob "*.cjs" \
            --glob "*.css" \
            --glob "*.html" || true)
        FILTERED_BUILD_CDN_REFS=$(print_filtered_matches "$BUILD_CDN_REFS")
        if [ -n "$FILTERED_BUILD_CDN_REFS" ]; then
            echo -e "${RED}❌ Found CDN reference in .next ($pattern):${NC}"
            echo "$FILTERED_BUILD_CDN_REFS"
            FOUND_EXTERNAL=1
        fi
    done
fi

# Check for analytics/tracking (high-signal only)
echo ""
echo "📊 Checking for analytics/tracking..."
echo "------------------------------------------"

ANALYTICS_PATTERNS=(
    "google-analytics"
    "googletagmanager.com"
    "gtag\\("
    "window\\.dataLayer"
    "segment\\.io"
    "mixpanel"
    "plausible\\.io"
    "posthog"
)
for pattern in "${ANALYTICS_PATTERNS[@]}"; do
    ANALYTICS_REFS=$(rg -n "$pattern" . \
        --glob "*.ts" \
        --glob "*.tsx" \
        --glob "*.js" \
        --glob "*.html" \
        "${RG_EXCLUDES[@]}" || true)
    FILTERED_ANALYTICS_REFS=$(print_filtered_matches "$ANALYTICS_REFS")
    if [ -n "$FILTERED_ANALYTICS_REFS" ]; then
        echo -e "${YELLOW}⚠ Found potential analytics reference ($pattern):${NC}"
        echo "$FILTERED_ANALYTICS_REFS"
        WARNINGS+=("Analytics reference found: $pattern")
    fi
done

# Check Google Fonts specifically
echo ""
echo "🔤 Checking for Google Fonts..."
echo "------------------------------------------"

FONT_REFS=$(rg -n "fonts.googleapis.com|fonts.gstatic.com" . \
    --glob "*.ts" \
    --glob "*.tsx" \
    --glob "*.js" \
    --glob "*.html" \
    --glob "*.css" \
    "${RG_EXCLUDES[@]}" || true)
FILTERED_FONT_REFS=$(print_filtered_matches "$FONT_REFS")
if [ -n "$FILTERED_FONT_REFS" ]; then
    echo -e "${RED}❌ Found Google Fonts references (MUST be self-hosted):${NC}"
    echo "$FILTERED_FONT_REFS"
    FOUND_EXTERNAL=1
fi

# Scanner/runtime errors are never equivalent to "no matches". Check the
# marker immediately before the summary so legacy capture sites cannot hide
# a failed scan.
if [ -s "$RG_ERROR_FILE" ]; then
    FIRST_RG_ERROR="$(head -n 1 "$RG_ERROR_FILE")"
    echo -e "${RED}❌ External dependency scan incomplete: ripgrep failed (status ${FIRST_RG_ERROR}).${NC}" >&2
    exit 2
fi

# Summary
echo ""
echo "=========================================="
echo "📊 Scan Summary"
echo "=========================================="

if [ $FOUND_EXTERNAL -eq 0 ]; then
    echo -e "${GREEN}✅ No external runtime dependencies found!${NC}"
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Warnings (non-blocking):${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  - $warning"
        done
    fi
    exit 0
else
    echo -e "${RED}❌ External dependencies found!${NC}"
    echo ""
    echo "Action required:"
    echo "1. Self-host all fonts and assets"
    echo "2. Remove or make optional all external API calls"
    echo "3. Document any intentional external dependencies"
    exit 1
fi
