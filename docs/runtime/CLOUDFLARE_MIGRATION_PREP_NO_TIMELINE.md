# Cloudflare Migration Prep (No Timeline)

## Phase 1: Domain & Zone Readiness
- Register `.com` domain.
- Prepare full DNS inventory for current roots/subdomains.
- Define canonical hosts:
  - main: `alirezasafaei.com`
  - audit: `audit.alirezasafaei.com`
  - toolbox: `tools.alirezasafaei.com` (or separate brand domain)

## Phase 2: Origin Hardening
- Keep TLS on origin with valid cert.
- Keep per-app health endpoints (`/api/ready`).
- Keep nginx routing per app isolated.
- Add fallback host policy (DNS-only emergency path).

## Phase 3: Edge Policy
- Start DNS-only, verify health and SEO paths.
- Enable proxy in controlled steps.
- Apply cache rules for static assets only.
- Keep API/dynamic paths bypassed from cache.

## Phase 4: SEO Continuity
- Add 301 redirects from old hosts to new hosts.
- Regenerate sitemap/canonical/hreflang.
- Re-verify all properties in Search Console.
- Re-submit sitemaps and key URLs.

## Phase 5: Traffic Cutover
- Gradual switch by host/subdomain.
- Watch uptime + error budget + crawl stats.
- Keep rollback DNS plan documented.

## Exit Criteria
- All three public hosts stable on proxy+VPN routes.
- GSC can read sitemap and index priority pages.
- No regression in performance and core user flows.
