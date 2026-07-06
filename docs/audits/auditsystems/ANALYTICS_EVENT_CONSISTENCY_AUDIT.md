# Analytics Event Consistency Audit — AuditSystems

**Date:** 2026-07-06
**Scope:** Read-only audit
**Status:** Complete

---

## Findings

### Event Names

| Event | Category | Usage |
|---|---|---|
| `seo_cta_click` | conversion | CTA registry, IntentRouter |
| `js_error` | engagement | Error boundary |

### CTA Registry Events

**File:** `src/lib/audit-cta-registry.ts`

All CTAs use consistent event structure:

```typescript
{
  name: "seo_cta_click",
  category: "conversion",
  metadata: {
    cta_id: string,      // stable ID
    intent: string,      // audit_start, sample_report, etc.
    surface: string,     // sample_report, audit_home, etc.
    destination: string  // URL
  }
}
```

**18 CTA entries** — all use `seo_cta_click` consistently.

### IntentRouter Events

**File:** `src/lib/intent-router-cta.ts`

IntentRouter wraps CTA registry — uses same `seo_cta_click` event with router metadata.

### Analytics Client

**File:** `src/lib/analytics.ts`

- Consent check via `localStorage.getItem("asdev_analytics_consent")`
- Event types: `conversion`, `engagement`, `web_vital`
- `seo_cta_click` is the only conversion event

### Consistency Check

| Aspect | Status |
|---|---|
| Event name consistency | ✅ All CTAs use `seo_cta_click` |
| Category consistency | ✅ All CTAs use `conversion` |
| Metadata structure | ✅ Consistent across registry |
| Consent handling | ✅ Checked before tracking |
| Missing events | ⚠️ No `audit_start` event (only CTA clicks) |

### Privacy/Consent

- ✅ Consent checked before tracking
- ✅ No tracking without consent
- ⚠️ Consent key is `asdev_analytics_consent` (not standard)

### Duplicated Events

None found — all CTA clicks use the same event name with different metadata.

### Inconsistent Naming

None found — naming is consistent.

---

## Recommendations

1. **Add `audit_start` event** — Track when audit actually starts (not just CTA click)
2. **Consider standard consent key** — Use industry-standard consent naming
3. **Add event documentation** — Document all events and their metadata fields

---

*Audit complete. No runtime changes recommended.*
