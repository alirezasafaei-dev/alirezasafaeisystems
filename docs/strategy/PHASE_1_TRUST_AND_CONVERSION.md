# Phase 1 — Trust and Conversion

**Status:** In progress (E1-01, E1-02 implemented in `auditsystems`)  
**Authority:** Execution notes for ASDEV Audit Platform  
**Last Updated:** 2026-07-06

---

## Goals

| ID | Goal | Acceptance |
|---|---|---|
| E1-01 | Credible sample report page | Anonymized findings, severity/category grouping, evidence, owners, conversion CTAs |
| E1-02 | Intent-based CTA registry | Stable IDs, intent, surface, destination, analytics event |

**Outcome:** A visitor understands ASDEV Audit, trusts the report format, and knows the next action.

---

## E1-01 — Sample Report

### Routes

- `/sample-report` (FA)
- `/en/sample-report` (EN)

### Implementation (auditsystems)

| Path | Purpose |
|---|---|
| `src/lib/sample-report/types.ts` | Finding types, categories, owners, difficulty |
| `src/lib/sample-report/demo-findings.ts` | Single anonymized demo dataset (FA+EN) |
| `src/lib/sample-report/copy.ts` | Locale strings and trust disclaimer |
| `src/components/sample-report/*` | Executive summary, grouped findings, CTAs |
| `src/app/sample-report/page.tsx` | FA route wrapper |
| `src/app/en/sample-report/page.tsx` | EN route wrapper |

### Trust rules

- Demo labeled **نمونه آموزشی / educational sample**
- Domain: `anonymous-example.ir` only
- No fake customer names, revenue, or ranking guarantees
- Score is illustrative (58/D)

### Conversion paths

- `/audit` — free assessment start
- `/audit?url=https://anonymous-example.ir` — prefill preserved
- `/pricing`, `/signup`
- Professional review → portfolio services (external UTM link)

---

## E1-02 — CTA Registry

### Canonical location

`auditsystems/src/lib/audit-cta-registry.ts`

### Intents

- `audit_start`
- `sample_report`
- `pricing_view`
- `signup`
- `agency_contact`
- `professional_review`

### Surfaces (implemented)

- `sample_report`
- `audit_home`
- `audit_landing`

### Component

`auditsystems/src/components/AuditCtaLink.tsx` — renders link + `seo_cta_click` analytics event.

### Cross-repo mapping (documentation only)

| PersianToolbox | AuditSystems |
|---|---|
| `audit-free-check` offer | `audit_start` intent |
| `tool-result-finance` placement | Consider routing to `/sample-report` (see below) |
| UTM `utm_source=toolbox` | Registry uses `utm_source=audit` on audit-native links |

**PersianToolbox soft routing (planned, not forced):**

- Update `audit-free-check.href` to `https://audit.alirezasafaeisystems.ir/sample-report?utm_*` when owner approves a single-line change
- PDF tool results (`tool-result-pdf`) — document only unless trivial

---

## Validation commands

### auditsystems (required)

```bash
cd sites/live/auditsystems
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```

### alirezasafaeisystems (docs only)

```bash
cd sites/live/alirezasafaeisystems
pnpm type-check
pnpm lint
pnpm test
pnpm build
```

---

## Out of scope (Phase 1)

- Production deployment
- Payment / billing activation
- DevAtlas, API platform, white-label
- New PersianToolbox tools or popups
- IntentRouter refactor (future: migrate to registry IDs)
- E1-03 trust page, E1-04 case studies, E1-05 hiring path

---

## Next tasks

1. **E1-03** — PersianToolbox local-first trust page
2. **E1-04** — Portfolio case studies with measured evidence
3. Wire portfolio hero/case-study links to audit CTA registry (optional, separate PR)
4. Consider smoke test for `/sample-report` in `scripts/smoke-public-routes.sh`