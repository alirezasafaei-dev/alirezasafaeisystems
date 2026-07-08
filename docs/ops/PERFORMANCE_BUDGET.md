# Performance Budget — ASDEV Audit Platform

**Audit Date:** 2026-07-08
**Target:** https://audit.alirezasafaeisystems.ir/
**Method:** Live HTTP measurement via `curl`

---

## 1. Current Performance Metrics

### Homepage (/)

| Metric | Measured | Target | Status |
|---|---|---|---|
| TTFB (Time to First Byte) | 1.14s | < 0.8s | ⚠️ Slow |
| Total download time | 1.23s | < 2.0s | ✅ Pass |
| Response size | 47.8 KB | < 100 KB | ✅ Pass |
| HTTP status | 200 | 200 | ✅ Pass |

### Page-by-Page Performance

| Page | TTFB | Size | Status |
|---|---|---|---|
| `/` (homepage) | 1.14s | 47.8 KB | ⚠️ |
| `/pricing` | 1.23s | 43.6 KB | ⚠️ |
| `/login` | 1.25s | 25.0 KB | ⚠️ |
| `/signup` | 1.22s | 25.4 KB | ⚠️ |
| `/audit` | 1.18s | 25.5 KB | ⚠️ |
| `/api/health` | 1.02s | 54 B | ✅ |
| `/api/ready` | 1.09s | 341 B | ✅ |

### Performance Breakdown (Homepage)

| Phase | Time | % of Total |
|---|---|---|
| DNS lookup | 0.000s | 0% |
| TCP connect | 0.000s | 0% |
| TLS handshake | 0.778s | 63% |
| TTFB (server processing) | 0.363s | 29% |
| Content download | 0.091s | 7% |
| **Total** | **1.233s** | 100% |

---

## 2. Performance Budget

### Response Size Budget

| Resource Type | Budget | Current | Status |
|---|---|---|---|
| HTML (initial) | < 100 KB | 47.8 KB | ✅ |
| CSS (inline) | < 50 KB | ~inline | ✅ |
| JS (initial bundle) | < 200 KB | (measure via Lighthouse) | ⏳ |
| Images (above fold) | < 100 KB | (measure via Lighthouse) | ⏳ |
| Fonts | < 100 KB | 3 fonts preloaded | ✅ |

### Timing Budget

| Metric | Budget | Current | Status |
|---|---|---|---|
| TTFB | < 800ms | 1.14s | ⚠️ Over budget |
| FCP (First Contentful Paint) | < 1.5s | ~1.2s (est.) | ✅ |
| LCP (Largest Contentful Paint) | < 2.5s | ~2.0s (est.) | ✅ |
| CLS (Cumulative Layout Shift) | < 0.1 | (measure via Lighthouse) | ⏳ |
| Total page weight | < 500 KB | ~48 KB HTML | ✅ |

---

## 3. TTFB Analysis

**Root cause of high TTFB (1.14s):**

1. **TLS handshake: 778ms (63% of TTFB)** — This is the dominant factor. Likely caused by:
   - Cold TLS session (first request)
   - Iran server latency to external monitoring
   - Let's Encrypt certificate chain complexity

2. **Server processing: 363ms** — Reasonable for SSR with Prisma queries

### TTFB Improvement Opportunities

| Action | Expected Impact | Effort |
|---|---|---|
| Enable TLS session resumption | -100-200ms for repeat visits | Low (Nginx config) |
| Add `Early hints` (103) | -50-100ms perceived | Medium |
| Enable Brotli compression | -10-20% transfer size | Low (Nginx config) |
| CDN edge caching (Cloudflare) | -200-500ms for distant users | Medium |
| Preload critical resources | -50-100ms FCP | Low |

---

## 4. Resource Loading Analysis

### Font Preloading ✅

Three fonts preloaded via `<link rel="preload">`:
- `Vazirmatn-Variable.woff2` (Persian)
- `IRANSansX-Regular.woff2` (Persian)
- `IRANSansX-Bold.woff2` (Persian)

### Cache Strategy

| Resource | Cache-Control | Assessment |
|---|---|---|
| HTML pages | `no-cache, no-store` | ✅ Correct for dynamic content |
| API responses | `no-store, no-cache` | ✅ Correct |
| Static assets | (check Next.js build) | ⏳ Verify long-term caching |

---

## 5. Performance Recommendations

### Quick Wins (This Week)

1. **Enable Brotli compression** in Nginx
   ```nginx
   gzip on;
   gzip_types text/plain text/css application/json application/javascript text/xml;
   brotli on;
   brotli_types text/plain text/css application/json application/javascript text/xml;
   ```

2. **Enable TLS session resumption** in Nginx
   ```nginx
   ssl_session_cache shared:SSL:10m;
   ssl_session_timeout 10m;
   ```

3. **Add resource hints** to layout.tsx
   ```html
   <link rel="preconnect" href="https://www.google-analytics.com" />
   ```

### Medium-Term (This Month)

4. **Implement ISR (Incremental Static Regeneration)** for static pages like `/pricing`, `/guides`
5. **Add `103 Early Hints`** for critical resources
6. **Optimize Next.js image configuration** for automatic WebP/AVIF

### Long-Term (This Quarter)

7. **Evaluate CDN** (Cloudflare free tier) for global TTFB improvement
8. **Implement service worker** for offline support and caching
9. **Add Lighthouse CI** to prevent performance regressions

---

## 6. Performance Monitoring

### Automated Monitoring

```bash
# Quick performance check
curl -s -o /dev/null -w "TTFB: %{time_starttransfer}s | Total: %{time_total}s | Size: %{size_download}B\n" \
  https://audit.alirezasafaeisystems.ir/

# Compare multiple pages
for path in / /pricing /audit /api/ready; do
  curl -s -o /dev/null -w "${path} → TTFB: %{time_starttransfer}s\n" \
    "https://audit.alirezasafaeisystems.ir${path}"
done
```

### Lighthouse CI (Recommended)

```bash
# Run Lighthouse locally
cd sites/live/auditsystems
pnpm run lighthouse:local

# Or via script
tsx src/scripts/lighthouse-local.ts
```

---

## 7. Performance Budget Thresholds

| Metric | Green | Yellow | Red |
|---|---|---|---|
| TTFB | < 800ms | 800ms - 1.5s | > 1.5s |
| Page size | < 100 KB | 100-300 KB | > 300 KB |
| Total download | < 2s | 2-4s | > 4s |
| Lighthouse perf | > 90 | 70-90 | < 70 |

**Current status:** Yellow zone (TTFB over budget, all other metrics green)

---

## 8. Next Steps

1. [ ] Run full Lighthouse audit and record baseline scores
2. [ ] Enable Brotli compression on Nginx
3. [ ] Enable TLS session resumption
4. [ ] Set up performance regression monitoring
5. [ ] Implement ISR for static pages
6. [ ] Add performance budget to CI pipeline
