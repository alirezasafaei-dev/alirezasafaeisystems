# Enterprise Runtime Status

Last updated (UTC): 2026-02-27T06:35:04Z
Base commit at capture: `ad5feec`

## Implemented baseline
- ASDEV cross-site contract: `/asdev` page + footer signature + UTM links + Telegram (`@asdevsystems`).
- Security headers baseline in Next config (CSP, HSTS, Referrer-Policy, XFO, XCTO, Permissions-Policy).
- `X-Robots-Tag: noindex, nofollow` for `/api/*` and admin surfaces.
- Request/correlation IDs handled in `src/proxy.ts`.
- Health endpoints: `/api/health`, `/api/ready`.
- CI smoke job for mobile `/asdev` added in `.github/workflows/ci.yml`.

## Latest real verification
- Environment snapshot:
  - Node.js: `v22.22.0`
  - pnpm: `9.15.0`
- Quality gates:
  - `pnpm type-check` -> PASS
  - `pnpm test` -> PASS (`23` files, `164` tests)
  - `pnpm run build` -> PASS (Next.js `16.1.6`)
  - `pnpm run test:e2e:smoke` -> PASS (`8/8`)
- Runtime evidence refresh:
  - `pnpm run codex:report` -> PASS
  - `bash scripts/codex/maintain-codex-cli.sh --no-commit --keep-days 30` -> PASS

## Notes
- Dynamic route signatures for readiness/health handlers are compatible with integration tests (`GET(_request: Request)`).
- Middleware duplicate removed; routing/security remains in `src/proxy.ts`.
- `docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md` and heartbeat are now aligned to the latest local runtime capture.
