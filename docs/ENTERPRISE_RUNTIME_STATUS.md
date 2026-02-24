# Enterprise Runtime Status

Last updated (UTC): 2026-02-24T00:39:28Z
Base commit at capture: `303b67d`

## Implemented baseline
- ASDEV cross-site contract: `/asdev` page + footer signature + UTM links + Telegram (`@asdevsystems`).
- Security headers baseline in Next config (CSP, HSTS, Referrer-Policy, XFO, XCTO, Permissions-Policy).
- `X-Robots-Tag: noindex, nofollow` for `/api/*` and admin surfaces.
- Request/correlation IDs handled in `src/proxy.ts`.
- Health endpoints: `/api/health`, `/api/ready`.
- CI smoke job for mobile `/asdev` added in `.github/workflows/ci.yml`.

## Latest real verification
- `pnpm type-check` -> PASS
- `pnpm run build` -> PASS
- Local production smoke:
  - server: `PORT=3111 pnpm run start`
  - test: `PLAYWRIGHT_DISABLE_WEBSERVER=true PLAYWRIGHT_BASE_URL=http://127.0.0.1:3111 pnpm exec playwright test e2e/smoke.spec.mjs --grep "asdev" --reporter=list`
  - result: PASS (1 passed)

## Notes
- Dynamic route signatures for readiness/health handlers are compatible with integration tests (`GET(_request: Request)`).
- Middleware duplicate removed; routing/security remains in `src/proxy.ts`.
