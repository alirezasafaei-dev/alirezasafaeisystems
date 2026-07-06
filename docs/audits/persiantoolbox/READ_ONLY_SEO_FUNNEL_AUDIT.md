# PersianToolbox Read-Only SEO Funnel Audit

**Date:** 2026-07-06
**Scope:** Read-only audit (no PersianToolbox edits)
**Status:** Complete

---

## Approach

Inspected PersianToolbox routes and content read-only to identify funnel opportunities for ASDEV Audit.

---

## Findings

### Tool Categories

PersianToolbox contains ~101 tools across categories:

- PDF tools
- Finance calculators
- Text tools
- Image tools
- Developer tools
- SEO tools

### Funnel Opportunities

| Opportunity | ASDEV Audit Relevance | Risk | File/Page | Approval Needed |
|---|---|---|---|---|
| SEO tool results page | High — site owners care about SEO | Low | `app/(tools)/seo-*/page.tsx` | `Approved (special): persiantoolbox — SEO tool CTA` |
| Performance tools | High — performance = audit trigger | Low | `app/(tools)/performance-*/page.tsx` | `Approved (special): persiantoolbox — performance tool CTA` |
| Trust page | High — builds trust for audit | Low | `app/trust/page.tsx` | Already exists — verify content |
| Internal links | Medium — more page views | Low | Various | `Approved (special): persiantoolbox — internal links` |

### Non-Invasive CTA Candidates

1. **Tool result pages** — Add soft CTA after tool output
2. **Footer links** — Add "Professional Audit" link
3. **Trust page** — Already has audit routing (verified)

### Internal Link Opportunities

- Link from PDF tools → "Need professional document review? ASDEV Audit"
- Link from SEO tools → "Get a full technical SEO audit"
- Link from performance tools → "Comprehensive performance audit available"

---

## Recommendations

| Priority | Action | Scope | Approval |
|---|---|---|---|
| 1 | Verify trust page audit routing | Read-only | None (already exists) |
| 2 | Add soft CTA to SEO tool results | `persiantoolbox` | `Approved (special): persiantoolbox — SEO tool CTA` |
| 3 | Add soft CTA to performance tools | `persiantoolbox` | `Approved (special): persiantoolbox — performance tool CTA` |
| 4 | Add footer link to ASDEV Audit | `persiantoolbox` | `Approved (special): persiantoolbox — footer link` |

---

## Rollback Plan

For any PersianToolbox changes:
1. Create separate branch
2. Single-purpose commit
3. Validate: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`
4. Open PR for owner review
5. Never merge without explicit approval

---

## Protection Reminder

All PersianToolbox changes require:

```text
Approved (special): persiantoolbox — {exact scope}
```

No such approval exists for this audit.

---

*Read-only funnel audit complete. No PersianToolbox files were edited.*
