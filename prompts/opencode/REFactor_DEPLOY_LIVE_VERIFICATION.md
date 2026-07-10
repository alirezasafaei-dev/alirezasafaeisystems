# OpenCode Prompt — Refactor Deploy Scripts for Mandatory Live Verification

Use this prompt with OpenCode, MiMo, or the automation host after `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md` lands.

```text
You are the ASDEV deployment reliability agent.

Mission:
Refactor deployment scripts, deployment docs, and automation steps so every production deploy is followed by mandatory real live verification using real browsers and operational checks. A deploy must never be reported as successful until live verification passes.

Mandatory policy to read first:
- docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md
- docs/governance/APPROVAL_GATES.md
- docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md
- docs/memory/ASDEV_CURRENT_STATE.md
- docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md

Target projects:
1. alirezasafaei-dev/alirezasafaeisystems
2. alirezasafaei-dev/persiantoolbox
3. alirezasafaei-dev/novax-price-alert
4. Any other ASDEV-owned deployed site discovered in project memory

Core rule:
Do not deploy. Do not rollback. Do not reload nginx. Do not change DNS. This task is to refactor scripts and docs only, unless the owner later gives the exact approval phrase.

Required implementation:

P0 — Inventory deployment scripts
- Find every deploy script, release script, smoke test, uptime check, readiness checklist, Cloudflare deploy, PM2 deploy, nginx switch, Docker/VPS deploy, and webhook deploy.
- Classify each as:
  - pre-deploy only
  - deploy/cutover
  - post-deploy verification
  - rollback
  - monitoring
- Report gaps.

P1 — Add or refactor live verification wrapper
For each project with a public site/service, add or update a script equivalent to:
- `scripts/deploy/live-verify.sh`
- or `scripts/ops/live-verify.sh`
- or project-native npm/pnpm script: `test:live`

The wrapper must support:
- base URL parameter
- desktop browser run
- mobile viewport run
- URL list
- navbar click checks where web UI exists
- critical route checks
- console/pageerror capture
- failed network request capture
- screenshots for P0/P1 failures
- JSON + Markdown report output
- non-zero exit on P0/P1 failure

P2 — Integrate live verification into deploy scripts
Refactor deploy scripts so:
- build/test/preflight runs before deploy
- deploy/cutover runs only under the existing approval gate
- post-deploy live verification runs immediately after deploy/cutover
- final success status requires live verification pass
- P0/P1 failure prints rollback target and rollback command
- report is written under `docs/reports/live-verification/` or `reports/live-verification/`

P3 — PersianToolbox special checks
Because PersianToolbox had live regressions after deploy, its verification must include:
- https://persiantoolbox.ir
- https://www.persiantoolbox.ir
- http→https redirect
- homepage
- blog index
- at least 10 blog posts or all blog posts if fewer
- navbar desktop clicks
- mobile menu clicks
- footer links
- critical tools: address, OCR, salary, check penalty, loan, base64, JSON formatter, image tools if present
- `_next/static` JS/CSS chunk checks
- service worker/cache checks if present
- direct hard refresh for routes
- client-side navigation for routes

P4 — Novax special checks
Because Novax is a Telegram bot + Worker endpoint, its verification must include:
- Worker /health
- webhook status instructions
- Telegram webhook pending count check if token is available locally and safely
- mini-app URL if configured
- bot deep-link/manual test checklist
- no payment leakage in groups test plan
- receipt/admin notification test plan

P5 — ASDEV Audit/Site checks
For ASDEV web properties, include:
- homepage
- audit entry page
- lead form public-safe path
- thank-you path if reachable without mutation or via test mode
- services/case studies conversion links
- admin pages only as protected-route checks, not unauthenticated success

P6 — Evidence and reporting
Every script must emit:
- verdict: LIVE_VERIFICATION_PASS / PASS_WITH_WARNINGS / FAIL_ROLLBACK_RECOMMENDED / FAIL_HOTFIX_REQUIRED / DEPLOY_BLOCKED_NOT_VERIFIED
- tested URL count
- browser/device list
- failures by severity
- report path
- screenshot/trace paths if present
- deployed commit/release id
- rollback target if known

P7 — Safety and secrets
- Do not commit screenshots/traces if huge.
- Do not commit secrets, env values, cookies, tokens, private admin data, or receipts.
- Redact environment values.
- Keep scripts project-local.
- Do not use global installs.

Validation:
- Run shell syntax checks for shell scripts.
- Run package tests where available.
- Run the live verification wrapper in dry-run or against a safe URL if possible.
- If browsers are unavailable, report the blocker and add install/setup docs; do not claim compliance.

Deliverables:
1. Policy wired into docs/scripts.
2. Live verification wrapper(s).
3. Deploy script integration.
4. Report template.
5. Updated README/OPERATIONS docs.
6. Queue/memory update.
7. Final report with changed files, tests, gaps, and next gated action.

Definition of done:
Deployment scripts cannot report success without live verification, and agents know this policy is mandatory.
```
