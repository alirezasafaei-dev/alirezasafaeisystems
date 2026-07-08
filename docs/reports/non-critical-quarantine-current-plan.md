# Non-Critical Site Quarantine — Current Plan

**Date:** 2026-07-08  
**Mode:** Planning only (no live quarantine)  
**CRITICAL_SITE:** `persiantoolbox.ir` — **never** quarantined

---

## Guardrails

| Rule | Status |
|------|--------|
| No live quarantine this cycle | Enforced |
| No delete / stop / nginx reload | Enforced |
| CRITICAL_SITE excluded | Hard-coded in `generate-quarantine-plan.sh` |
| Inventory required before allowlist | Required |

---

## Registry sites (deploy allowlist context)

| site_id | priority | protected | Quarantine candidate? |
|---------|----------|-----------|------------------------|
| persiantoolbox | 1 | true | **NEVER** |
| alirezasafaeisystems | 2 | false | Maybe (owner review) |
| auditsystems | 3 | false | Maybe (owner review) |
| devatlas | 4 | false | Maybe (owner review) |

Registry membership ≠ automatic quarantine eligibility. IRAN_PROD may host additional non-registry apps.

---

## Tooling already present

- `scripts/ops/generate-quarantine-plan.sh` — builds allowlist + markdown from inventory JSON
- `scripts/ops/quarantine-non-critical.sh` — **must not** run live without separate approval
- Branch history: `ops/cleanup-quarantine-plan` (planning work)

---

## Execution plan (when approved later)

1. Collect IRAN_PROD inventory JSON (read-only SSH) → store redacted under `docs/reports/`
2. Run `generate-quarantine-plan.sh inventory.json --output-dir …`
3. Owner review allowlist (exclude anything unknown)
4. Dry-run quarantine script only
5. Require explicit phrase before any live quarantine (not granted in master loop)

---

## Required future approval (not granted now)

```
APPROVE_NON_CRITICAL_QUARANTINE_LIVE
```

---

## This cycle status

**PLAN_ONLY_COMPLETE** — no inventory mutation, no remote quarantine.
