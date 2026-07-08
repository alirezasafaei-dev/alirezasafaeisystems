# SEO Basics Audit — ASDEV Audit Platform

**Audit Date:** 2026-07-08
**Target:** https://audit.alirezasafaeisystems.ir/
**Method:** Live HTTP inspection + source analysis

---

## 1. Technical SEO Checklist

### Meta Tags

| Tag | Homepage | Pricing | Login | Signup | Audit | Status |
|---|---|---|---|---|---|---|
| `<title>` | ✅ Unique | ✅ Unique | ⚠️ Generic | ⚠️ Generic | ✅ Unique | Partial |
| `<meta description>` | ✅ Present | ⏳ Verify | ⏳ Verify | ⏳ Verify | ⏳ Verify | Partial |
| `<meta robots>` | ✅ index, follow | — | — | — | — | ✅ |
| `<link rel="canonical">` | ✅ Present | ⏳ Verify | ⏳ Verify | ⏳ Verify | ⏳ Verify | Partial |
| Open Graph tags | ✅ Present | ⏳ Verify | ⏳ Verify | ⏳ Verify | ⏳ Verify | Partial |
| Twitter cards | ⏳ Verify | — | — | — | — | Unknown |

### Homepage Meta Tags (Verified)

```html
<title>چک کردن سایت - مشکلات و راه حل</title>
<meta name="description" content="آدرس سایت خود را وارد کنید و ببینید چه مشکلاتی دارد..."/>
<meta name="robots" content="index, follow"/>
<link rel="canonical" href="https://audit.alirezasafaeisystems.ir"/>
<meta property="og:title" content="چک کردن سایت - مشکلات و راه حل"/>
<meta property="og:description" content="آدرس سایت خود را وارد کنید..."/>
<meta property="og:url" content="https://audit.alirezasafaeisystems.ir"/>
<meta property="og:site_name" content="Alireza Safaei Audit Platform"/>
<meta property="og:type" content="website"/>
```

**Assessment:** ✅ Homepage SEO is solid. Unique title, descriptive canonical URL, proper OG tags.

---

## 2. Sitemap

**Status:** ✅ Present at `/sitemap.xml`

| Check | Status |
|---|---|
| Sitemap exists | ✅ 200 |
| Valid XML | ✅ Proper urlset format |
| hreflang tags | ✅ FA-IR / EN-US / x-default |
| lastmod dates | ✅ Present (2026-03-01) |
| Priority values | ✅ 0.75 - 1.0 |
| changefreq | ✅ weekly |
| Referenced in robots.txt | ✅ |

### Sitemap Pages

| URL | Priority | hreflang |
|---|---|---|
| `/` | 1.0 | fa-IR, en-US, x-default |
| `/en` | 0.95 | fa-IR, en-US, x-default |
| `/audit` | 0.8 | fa-IR, en-US |
| `/en/audit` | 0.75 | fa-IR, en-US |
| `/guides` | 0.8 | fa-IR, en-US |
| `/en/guides` | — | fa-IR, en-US |

### Sitemap Issues

1. **lastmod is static (2026-03-01)** — Should update dynamically based on content changes
2. **Missing pages** — `/pricing`, `/login`, `/signup`, `/faq`, `/blog`, `/case-studies`, `/standards` not in sitemap
3. **No image sitemap** — Consider adding for visual content

---

## 3. Robots.txt

**Status:** ✅ Present at `/robots.txt`

```
User-Agent: *
Allow: /
Allow: /en
Allow: /guides
Allow: /en/guides
Allow: /pillar
Allow: /en/pillar
Allow: /sample-report
Allow: /en/sample-report
Allow: /audit
Allow: /en/audit
Allow: /standards
Allow: /en/standards
Disallow: /api/
Disallow: /audit/r/
Disallow: /en/audit/r/
Disallow: /failed
Disallow: /en/failed
Disallow: /brand/asdev-portfolio
Disallow: /en/brand/asdev-portfolio
Disallow: /asdev

Host: audit.alirezasafaeisystems.ir
Sitemap: https://audit.alirezasafaeisystems.ir/sitemap.xml
```

**Assessment:** ✅ Well-configured. Properly blocks API and internal routes, allows public pages.

---

## 4. Structured Data (JSON-LD)

**Status:** ✅ Present on homepage

| Schema Type | Present | Assessment |
|---|---|---|
| `application/ld+json` | ✅ 2 blocks | Good |
| `schema.org` references | ✅ Present | Good |

### Missing Structured Data

| Schema | Page | Priority |
|---|---|---|
| `Product` / `Offer` | `/pricing` | High — enables rich snippets |
| `FAQPage` | `/faq` | Medium — FAQ rich results |
| `Article` | `/blog/*` | Medium — blog rich results |
| `BreadcrumbList` | All pages | Low — breadcrumb rich results |
| `Organization` | Homepage | Medium — knowledge panel |

---

## 5. International SEO (hreflang)

**Status:** ✅ Implemented

| Check | Status |
|---|---|
| FA-IR default | ✅ `/` serves Persian |
| EN-US alternate | ✅ `/en` serves English |
| x-default | ✅ Points to `/` |
| hreflang in sitemap | ✅ All pages |
| hreflang in HTML | ⏳ Verify `<link>` tags |

---

## 6. Page Speed & Core Web Vitals

| Metric | Measured | Target | Status |
|---|---|---|---|
| TTFB | 1.14s | < 0.8s | ⚠️ |
| Page size | 47.8 KB | < 100 KB | ✅ |
| HTTPS | ✅ | Required | ✅ |
| Mobile-friendly | ⏳ | Required | ⏳ Verify |

---

## 7. Content SEO

### Homepage Content

- **Title length:** 30 chars (FA) — ✅ Optimal
- **Description length:** ~120 chars (FA) — ✅ Optimal
- **H1 tag:** ⏳ Verify
- **Keyword density:** ⏳ Manual review needed

### Missing Content Pages

| Page | Status | SEO Value |
|---|---|---|
| `/blog` | ✅ Present | High — long-tail keywords |
| `/guides` | ✅ Present | High — educational content |
| `/faq` | ✅ Present | Medium — FAQ rich results |
| `/case-studies` | ✅ Present | Medium — trust + long-tail |
| `/sample-report` | ✅ Present | High — conversion intent |
| `/pillar` | ✅ Present | High — topic authority |

---

## 8. SEO Issues Found

### High Priority

1. **Missing pages in sitemap** — `/pricing`, `/login`, `/signup`, `/faq`, `/blog`, `/case-studies`, `/standards` not listed
2. **Static lastmod dates** — All sitemap entries show `2026-03-01`, not reflecting actual content updates
3. **Login/Signup generic titles** — Both show "سیستم ممیزی علیرضا صفایی" instead of page-specific titles

### Medium Priority

4. **No `Product` schema on pricing** — Missing opportunity for rich snippets
5. **No `FAQPage` schema** — Missing opportunity for FAQ rich results
6. **No Twitter card meta tags** — Missing `twitter:card`, `twitter:title`, `twitter:description`

### Low Priority

7. **No breadcrumb navigation** — Consider adding for UX + rich results
8. **No `Organization` schema** — Could improve knowledge panel
9. **Image alt text** — Verify all images have descriptive alt attributes

---

## 9. SEO Recommendations

### Quick Wins (This Week)

1. **Add missing pages to sitemap** — Update `src/app/sitemap.ts`
2. **Fix login/signup titles** — Add page-specific `<title>` tags
3. **Add Twitter card meta tags** — Add to layout.tsx

### Medium-Term (This Month)

4. **Implement dynamic lastmod** — Update sitemap to use actual content timestamps
5. **Add `Product` schema to pricing** — Enable rich snippets
6. **Add `FAQPage` schema** — Enable FAQ rich results
7. **Add `Organization` schema** — Improve knowledge panel

### Long-Term (This Quarter)

8. **Add breadcrumb navigation** — UX + rich results
9. **Implement blog schema** — `Article` markup for blog posts
10. **Add hreflang `<link>` tags** in HTML head (verify if not present)

---

## 10. Verification Commands

```bash
# Check sitemap
curl -s https://audit.alirezasafaeisystems.ir/sitemap.xml | head -50

# Check robots.txt
curl -s https://audit.alirezasafaeisystems.ir/robots.txt

# Check meta tags on all pages
curl -s https://audit.alirezasafaeisystems.ir/ | grep -oi '<title>[^<]*</title>\|<meta name="description"[^>]*>\|<link rel="canonical"[^>]*>'

# Check structured data
curl -s https://audit.alirezasafaeisystems.ir/ | grep -c 'application/ld+json'

# Check hreflang
curl -s https://audit.alirezasafaeisystems.ir/ | grep -i 'hreflang'

# Run SEO audit script
cd sites/live/auditsystems
pnpm seo:audit
```
