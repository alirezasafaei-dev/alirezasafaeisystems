# Discover Production Completion — 2026-08-20

Status: `LIVE_VERIFICATION_PASS`

- ASDEV Audit goal: better production reliability, trusted acquisition content, and lower operational risk.
- GITHUB_MAIN merge: `816a4b3f37566bbe1f9bde2537831ab20dc5d2e8` via PR #186.
- Deployment: GitHub Actions run `32343702766`; IRAN_PROD_SERVER release `20260820T072441Z`.
- Published resource: `persiantoolbox`, item id `cmt157spi0000qus3lx2fcwt7`, official URL `https://persiantoolbox.ir/`.
- Telegram guide: intentionally absent; no authoritative message-level Telegram URL was available.
- Admin/API lifecycle: authenticated list, unpublished create, unpublished route protection, and publish transition verified.
- Database: 8 migrations applied; schema up to date; Prisma diff reported `No difference detected.`
- Deployment snapshot: `/var/www/my-portfolio/shared/backups/production/20260820T072441Z/database.sqlite`.
- Manual pre-content backup: `/var/www/my-portfolio/shared/backups/manual-discover/20260820T063128Z`.
- Rollback releases: `20260820T054736Z` and `20260819T132120Z`.
- Live routes: `/discover`, `/en/discover`, and both localized `persiantoolbox` details returned 200 with canonical metadata, structured data, exact official CTA, and no `noindex`.
- Sitemap: `/sitemap.xml` contains `/discover/persiantoolbox` after the dynamic sitemap correction.
- Browser evidence: two consecutive desktop/mobile Chromium passes, six URLs each, no failures and no warnings; workflow artifact `live-verification-32343702766`.
- Quality: 314 tests, type-check, build, lint, high/critical audit, secret scan, E2E smoke, Lighthouse, dependency review, and CodeQL passed.