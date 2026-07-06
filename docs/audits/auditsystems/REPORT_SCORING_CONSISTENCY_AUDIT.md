# Report Scoring Consistency Audit — AuditSystems

**Date:** 2026-07-06
**Scope:** Read-only audit
**Status:** Complete

---

## Findings

### Scoring Logic

The sample report uses a fixed illustrative score:

- **Score:** 58/D (hardcoded in demo-findings.ts)
- **Grade:** Displayed via `copy.ts` grade labels (FA/EN)
- **No dynamic scoring engine** found in client code

### Grade Thresholds

No explicit A/B/C/D/F threshold definitions found. The sample report shows a single grade "D" with the score 58.

### Scoring Dimensions

The sample report groups findings by category:

- Performance
- Security
- SEO
- Accessibility
- Best Practices

Each finding has:
- `category`: string
- `severity`: critical | high | medium | low | info
- `title`: localized string
- `description`: localized string
- `evidence`: optional object

### Edge Cases

1. **No scoring formula visible** — The score appears to be pre-computed, not derived from findings at runtime
2. **Grade labels exist** but no mapping from score range to grade
3. **Demo data is static** — No dynamic score calculation from findings

### Mismatches

None found — the score (58/D) is consistently displayed across FA and EN locales.

### Missing Tests

- No tests for score-to-grade mapping
- No tests for scoring formula
- No tests for edge cases (0 score, 100 score, negative values)

---

## Recommendations

1. **Document scoring formula** — If dynamic scoring exists in backend, document it
2. **Add grade threshold tests** — Test score ranges map to correct grades
3. **Consider dynamic scoring** — Derive score from actual findings for real audits

---

*Audit complete. No runtime changes recommended.*
