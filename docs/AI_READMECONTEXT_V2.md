# README v2 Context for Next Agent

- Requested by user: continue from this point and let the "model-pro" draft version 2 of the repository README.

## Confirmed current state (production/live)
- Main domains checked with `live-surface-audit`: pass.
- `admin` surface exists and is behind auth checks:
  - UI: `/admin`, `/admin/login`
  - Protected via middleware proxy and session/token auth in:
    - `src/proxy.ts`
    - `src/lib/admin-auth.ts`
  - metadata on admin pages sets `robots: { index:false, follow:false }`.
- Sitemap is present and generated:
  - `src/app/sitemap.ts`
  - manifest source: `src/generated/sitemap-manifest.json`
  - live check: `https://alirezasafaeisystems.ir/sitemap.xml` returns 200.
- `https://alirezasafaeisystems.ir/robots.txt` returns 200 and disallows `/admin/`.

## Useful direct checks executed
- `bash alirezasafaeisystems/scripts/network/live-surface-audit.sh`
- `curl -I https://alirezasafaeisystems.ir/admin`
- `curl -I https://alirezasafaeisystems.ir/admin/login`
- `curl -I https://alirezasafaeisystems.ir/robots.txt`
- `curl -I https://alirezasafaeisystems.ir/sitemap.xml`

## Latest git checkpoint
- `ce01380` : docs: record live-domain health guardrail results and cert fix

## Suggestion for README v2
- Add concise “What this repo includes” section:
  - Live portfolio app + admin dashboard
  - SEO stack (robots + sitemap)
  - API surfaces (/api/*), rate limiting, CSP
- Add “Ops and health” section mentioning health/surface check command and known domains.
- Add “Deployment/Infrastructure” section with domains and HTTPS status.
