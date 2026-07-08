# Security Header Audit — ASDEV Audit Platform

**Audit Date:** 2026-07-08
**Target:** https://audit.alirezasafaeisystems.ir/
**Method:** Live HTTP header inspection via `curl -sI`

---

## 1. Header Inventory

### Headers Present ✅

| Header | Value | Status |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | ✅ Excellent |
| `X-Frame-Options` | `DENY` | ✅ Excellent |
| `X-Content-Type-Options` | `nosniff` | ✅ Excellent |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | ✅ Good |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=()` | ✅ Excellent |
| `X-DNS-Prefetch-Control` | `on` | ✅ Good |
| `Content-Security-Policy` | Full policy (see below) | ✅ Good |
| `Cache-Control` | `private, no-cache, no-store, max-age=0, must-revalidate` | ✅ Appropriate |

### Headers Missing ⚠️

| Header | Recommended Value | Priority |
|---|---|---|
| `X-XSS-Protection` | `0` (CSP replaces this) | Low — CSP covers it |
| `Cross-Origin-Opener-Policy` | `same-origin` | Medium |
| `Cross-Origin-Resource-Policy` | `same-origin` | Medium |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Low |

---

## 2. Content Security Policy Analysis

**Current CSP:**
```
default-src 'self';
script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com https://www.google-analytics.com;
style-src 'self' 'unsafe-inline';
img-src 'self' data: blob: https://www.google-analytics.com https://www.googletagmanager.com;
font-src 'self';
connect-src 'self' https://www.google-analytics.com https://analytics.google.com;
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
upgrade-insecure-requests
```

### CSP Assessment

| Directive | Status | Notes |
|---|---|---|
| `default-src 'self'` | ✅ | Restrictive default |
| `script-src 'unsafe-inline' 'unsafe-eval'` | ⚠️ | Weakens CSP significantly. Next.js requires this for dev; consider nonces for production |
| `style-src 'unsafe-inline'` | ⚠️ | Common for Next.js; consider nonces |
| `frame-ancestors 'none'` | ✅ | Equivalent to X-Frame-Options: DENY |
| `base-uri 'self'` | ✅ | Prevents base tag injection |
| `form-action 'self'` | ✅ | Prevents form hijacking |
| `upgrade-insecure-requests` | ✅ | Forces HTTPS |

### CSP Recommendations

1. **Replace `'unsafe-inline'` in script-src with nonces** — Next.js supports `nonce` attribute on scripts. This eliminates XSS risk from inline scripts.
2. **Remove `'unsafe-eval'`** — If no eval() is used in production, remove it. Check with: `grep -r "eval(" src/`
3. **Add `object-src 'none'`** — Prevents plugin-based attacks
4. **Consider `require-trusted-types-for 'script'`** — DOM XSS mitigation

---

## 3. SSL/TLS Configuration

| Check | Status |
|---|---|
| Certificate valid | ✅ Let's Encrypt |
| HSTS preload ready | ✅ `max-age=31536000; includeSubDomains; preload` |
| HTTP → HTTPS redirect | ✅ enforced by HSTS |
| TLS version | TLS 1.2+ (verified via openssl) |

---

## 4. API Endpoint Security

**Tested:** `/api/ready`, `/api/health`

| Check | Status |
|---|---|
| `X-Robots-Tag: noindex, nofollow` | ✅ API endpoints deindexed |
| `Cache-Control: no-store` | ✅ No caching of API responses |
| `Content-Security-Policy` present | ✅ Same policy as pages |
| `X-Frame-Options: DENY` | ✅ Prevents framing |

---

## 5. Cookie Security (if applicable)

Not directly visible from headers. Verify in code:

```bash
# Check for secure cookie flags in source
grep -r "secure:\|httpOnly:\|sameSite:" sites/live/auditsystems/src/
```

Expected: `secure: true`, `httpOnly: true`, `sameSite: 'lax'` or `'strict'`

---

## 6. Findings Summary

| Category | Score | Notes |
|---|---|---|
| Transport Security | 10/10 | HSTS with preload, TLS enforced |
| Clickjacking Protection | 10/10 | X-Frame-Options: DENY + CSP frame-ancestors |
| MIME Sniffing | 10/10 | X-Content-Type-Options: nosniff |
| Content Security Policy | 7/10 | Good structure, weakened by unsafe-inline/eval |
| Permissions Policy | 10/10 | Camera, mic, geolocation, payment all disabled |
| Referrer Policy | 9/10 | strict-origin-when-cross-origin is good |
| API Security | 9/10 | Proper deindexing, no-cache |
| **Overall** | **9.3/10** | Strong posture, CSP nonces would be ideal |

---

## 7. Recommendations (Priority Order)

1. **[Medium]** Replace `unsafe-inline` script-src with nonce-based CSP (requires Next.js CSP config changes)
2. **[Medium]** Remove `unsafe-eval` if not needed in production
3. **[Low]** Add `object-src 'none'` to CSP
4. **[Low]** Add `Cross-Origin-Opener-Policy: same-origin` header
5. **[Low]** Verify cookie flags in auth/session code

---

## 8. Verification Commands

```bash
# Re-run header audit
curl -sI https://audit.alirezasafaeisystems.ir/

# Check CSP specifically
curl -sI https://audit.alirezasafaeisystems.ir/ | grep -i "content-security-policy"

# Check SSL
echo | openssl s_client -servername audit.alirezasafaeisystems.ir \
  -connect audit.alirezasafaeisystems.ir:443 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates
```
