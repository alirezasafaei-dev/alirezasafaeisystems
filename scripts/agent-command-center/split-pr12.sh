#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDITSYSTEMS_DIR="${SCRIPT_DIR}/../../sites/live/auditsystems"

cd "$AUDITSYSTEMS_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[SPLIT]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

MAIN_BRANCH="main"
MEGA_BRANCH="product/audit-reliability-conversion-pack"

log "Ensuring we're on ${MEGA_BRANCH}"
git checkout "$MEGA_BRANCH" 2>/dev/null || true

create_focused_branch() {
  local branch_name="$1"
  local title="$2"
  shift 2
  local files=("$@")

  log "Creating branch: ${branch_name}"
  git checkout "$MAIN_BRANCH"
  git checkout -b "$branch_name" 2>/dev/null || { git branch -D "$branch_name" 2>/dev/null; git checkout -b "$branch_name"; }

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      mkdir -p "$(dirname "$file")"
      git checkout "$MEGA_BRANCH" -- "$file" 2>/dev/null || true
    fi
  done

  git add -A
  if git diff --cached --quiet; then
    log "No changes for ${branch_name}, skipping"
    git checkout "$MAIN_BRANCH"
    git branch -D "$branch_name" 2>/dev/null || true
    return 0
  fi

  git commit -m "$title"
  ok "Branch ${branch_name} created with ${#files[@]} files"
  git checkout "$MAIN_BRANCH"
}

log "=== PR-A: retry + analytics ==="
create_focused_branch "product/retry-analytics-focused" \
  "feat(audit): harden retry UX and analytics events" \
  "src/app/audit/AuditPageClient.tsx" \
  "src/app/en/audit/AuditPageClient.tsx" \
  "src/lib/analytics.ts"

log "=== PR-B: sample report trust ==="
create_focused_branch "product/sample-report-trust-focused" \
  "feat(report): clarify sample report trust signals" \
  "src/components/sample-report/TrustDisclaimer.tsx" \
  "src/lib/sample-report/copy.ts"

log "=== PR-C: CTA + smoke ==="
create_focused_branch "product/cta-smoke-focused" \
  "chore(audit): harden CTA registry and public smoke coverage" \
  "scripts/smoke-full.sh" \
  "src/lib/reportShare.ts"

log "=== PR-D: deploy workflow (BLOCKED) ==="
create_focused_branch "ops/vps-deploy-workflow-quarantine" \
  "ops(deploy): quarantine VPS deploy workflow for owner review" \
  ".github/workflows/deploy-vps-manual.yml" \
  "ops/deploy/deploy.sh" \
  "docs/runtime/VPS_DEPLOY_2026-07-05.md"

log "=== PR-E: schema features (BLOCKED) ==="
create_focused_branch "product/schema-features-quarantine" \
  "feat(saas): quarantine schema-backed product features" \
  "prisma/schema.prisma" \
  "src/lib/subscription.ts" \
  "src/lib/subscription.test.ts" \
  "src/lib/__tests__/payment-flow.test.ts" \
  "src/app/api/billing/checkout/route.ts" \
  "src/app/api/reports/[token]/capture/route.ts" \
  "src/lib/team-auth.ts" \
  "src/app/api/team/route.ts" \
  "src/app/app/team/page.tsx" \
  "src/app/api/referrals/route.ts" \
  "src/app/app/referrals/page.tsx" \
  "src/lib/referral.ts" \
  "src/app/api/settings/brand/route.ts" \
  "src/app/app/settings/brand/page.tsx" \
  "src/app/api/notifications/history/route.ts" \
  "src/app/api/notifications/preferences/route.ts" \
  "src/app/api/notifications/unsubscribe/route.ts" \
  "src/app/app/notifications/page.tsx" \
  "src/lib/notifications.ts" \
  "src/app/api/admin/monitoring/route.ts" \
  "src/app/admin/monitoring/page.tsx" \
  "src/lib/monthly-report.ts" \
  "src/scripts/generate-monthly-reports.ts" \
  "src/app/app/reports/page.tsx"

log "=== PR-F: content (blog + case-studies) ==="
create_focused_branch "content/blog-case-studies-focused" \
  "content: add ASDEV Audit blog and case-study library" \
  "src/content/blog/core-web-vitals-guide.ts" \
  "src/content/blog/technical-seo-issues.ts" \
  "src/content/blog/seo-checklist.ts" \
  "src/content/blog/seo-report-client.ts" \
  "src/content/blog/website-audit-guide.ts" \
  "src/content/blog/ecommerce-audit.ts" \
  "src/content/blog/security-audit-guide.ts" \
  "src/content/blog/seo-audit-checklist.ts" \
  "src/content/blog/website-speed-test.ts" \
  "src/content/blog/wordpress-seo.ts" \
  "src/content/blog/index.ts" \
  "src/content/case-studies/agency-client-reports.ts" \
  "src/content/case-studies/ecommerce-improvement.ts" \
  "src/content/case-studies/wordpress-security.ts" \
  "src/content/case-studies/index.ts" \
  "src/app/blog/[slug]/page.tsx" \
  "src/app/blog/page.tsx" \
  "src/app/case-studies/[slug]/page.tsx" \
  "src/app/case-studies/page.tsx"

log "=== PR-G: scripts + backup ==="
create_focused_branch "chore/scripts-smoke-backup-focused" \
  "chore(ops): add backup restore and smoke tooling" \
  "scripts/backup-db.sh" \
  "scripts/restore-db.sh" \
  "src/lib/logger.ts" \
  "src/lib/security-log.ts" \
  "src/lib/account-lockout.ts"

log "=== All focused branches created ==="
git checkout "$MEGA_BRANCH"
git log --oneline -1
ok "Split complete"
