# Phase 1 — Trust and Conversion

**Status:** E1-01 through E1-05 complete (2026-07-06)  
**Authority:** Execution notes for ASDEV Audit Platform  
**Last Updated:** 2026-07-06

---

## Goals

| ID | Goal | Status |
|---|---|---|
| E1-01 | Credible sample report page | ✅ Done (`auditsystems`) |
| E1-02 | Intent-based CTA registry | ✅ Done + hardened (`auditsystems`) |
| E1-03 | PersianToolbox local-first trust page | ✅ Done (`/trust` + audit routing) |
| E1-04 | Portfolio case studies with evidence | ✅ Done (`docs/projects/*`) |
| E1-05 | Inquiry / qualification path | ✅ Done (`/qualification`, `INQUIRY_PATH.md`) |

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

---

## E1-02 — CTA Registry (hardened)

### Canonical location

- Registry: `auditsystems/src/lib/audit-cta-registry.ts`
- Component: `auditsystems/src/components/AuditCtaLink.tsx`
- Tracking: `auditsystems/src/lib/audit-cta-tracking.ts`
- IntentRouter adapter: `auditsystems/src/lib/intent-router-cta.ts`
- Docs: `auditsystems/docs/CTA_REGISTRY.md`

### Surfaces (registry-backed)

- `sample_report`, `audit_home`, `audit_landing`, `pricing_page`
- IntentRouter clicks via adapter (layout unchanged)

### Ad-hoc (documented, unchanged)

- Layout navigation links
- Pricing plan signup buttons (billing scope)
- EN homepage hero external links
- FAQ/failed retry links

### Smoke coverage

`scripts/smoke-public-routes.sh` includes `/sample-report`, `/en/sample-report`, `/en/audit`, `/en/pricing`.

---

## E1-03 — PersianToolbox trust

- Route: `/trust`
- ASDEV Audit differentiation section (local file tools vs URL audit)
- `audit-free-check` CTA → sample report with UTM
- Soft links: homepage trust section, PDF tools hub

---

## E1-04 — Case studies

| Doc | Project |
|---|---|
| `docs/projects/auditsystems.md` | ASDEV Audit Platform |
| `docs/projects/persiantoolbox.md` | PersianToolbox |
| `docs/projects/alirezasafaeisystems.md` | Brand / mother site |

Unverified metrics marked **Evidence pending** or **Measurement not yet public-safe**.

---

## E1-05 — Inquiry path

- App route: `/qualification`
- Strategy doc: `docs/strategy/INQUIRY_PATH.md`
- Primary product path: Audit sample report + audit start
- No fake hiring copy

---

## Phase 2 entry

- `persiantoolbox/docs/growth/HIGH_VALUE_TOOL_TEMPLATE.md` — tool page pattern for audit acquisition

---

## Validation commands

### auditsystems

```bash
cd sites/live/auditsystems
pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

### persiantoolbox

```bash
cd sites/live/persiantoolbox
pnpm typecheck && pnpm lint && (pnpm test:ci || pnpm test) && pnpm build
```

### alirezasafaeisystems

```bash
cd sites/live/alirezasafaeisystems
pnpm type-check && pnpm lint && pnpm test && pnpm build
```

---

## Out of scope (Phase 1)

- Production deployment
- Payment / billing activation
- DevAtlas standalone, API platform, white-label
- New PersianToolbox tools or popups
- Fake metrics or hiring claims

---

## Next tasks (Phase 2+)

1. Apply high-value tool template to one finance tool result area
2. Conversion funnel reporting (E3-04)
3. Wire portfolio UI case-study cards to updated docs (optional)
4. EN CSRF / deploy WIP — separate owner commits