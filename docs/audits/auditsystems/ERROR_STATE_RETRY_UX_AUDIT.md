# Error-State and Retry UX Audit — AuditSystems

**Date:** 2026-07-06
**Scope:** Read-only audit
**Status:** Complete

---

## Findings

### Audit Submission Flow

**File:** `src/app/audit/AuditPageClient.tsx`

User submits URL → POST to `/api/projects/[projectId]/audit` → Response with status

### Error States Found

| Error Code | User Message (EN) | Retry? |
|---|---|---|
| `RATE_LIMITED` | "Too many requests. Please retry in a few minutes." | Yes |
| `DNS_LOOKUP_FAILED` | "DNS lookup is required; please try again shortly." | Yes |
| `RATE_LIMIT_BACKEND_REQUIRED` | "Distributed rate-limit backend temporarily unavailable." | Yes |
| `INVALID_URL_EMPTY` | "Target URL is required." | No (fix input) |
| `INVALID_URL_TOO_LONG` | "Target URL is too long." | No (fix input) |
| `INVALID_URL_*` | "URL is valid. Provide a full public URL." | No (fix input) |
| `SSRF_BLOCKED_*` | "This URL is blocked. Use a reachable public hostname." | No (fix input) |
| `AUDIT_LIMIT_REACHED` | "Free plan allows N audits per month. Upgrade to run more." | No (upgrade) |

### Retry Logic

- **No automatic retry** — User must manually resubmit
- **Loading state** — `isSubmitting` flag disables button during request
- **Error display** — `message` state shows error text

### Loading States

- ✅ Button disabled during submission
- ✅ Loading text shown ("در حال بررسی..." / "Checking...")
- ✅ Visual feedback (opacity change)

### Empty States

- ✅ "No run submitted yet." shown before first submission

### Missing Retry Helpers

1. **No auto-retry** for transient errors (RATE_LIMITED, DNS_LOOKUP_FAILED)
2. **No countdown timer** for rate-limited state
3. **No "Try Again" button** — user must re-enter URL and submit

---

## Quick Wins

1. **Add "Try Again" button** for retryable errors (copy-only change)
2. **Add retry count** display for transient errors
3. **Add estimated wait time** for rate-limited state

---

## Recommendations

1. Implement auto-retry for DNS_LOOKUP_FAILED (1 retry after 5s)
2. Add "Try Again" button for RATE_LIMITED errors
3. Consider exponential backoff UI for repeated failures

---

*Audit complete. No runtime changes recommended.*
