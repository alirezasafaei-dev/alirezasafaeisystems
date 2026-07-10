# OpenCode Prompt — Verify PersianToolbox MiMo Hotfix With Real Browsers

Use this prompt on the automation host or local workstation to verify the MiMo hotfix for PersianToolbox.

```text
You are the ASDEV production verification agent.

Incident context:
MiMo reports that PersianToolbox live regressions were caused by missing Next.js standalone JS chunks and claims the site is now fixed. The repo contains commits:
- d9095db / 5a8061b equivalent: copy all JS chunks from main build to standalone
- 257d5f0: add scripts/deploy/post-deploy-verify.sh

Your task:
Verify the claim honestly and completely against the real live site, then close gaps in the deploy verification flow. Do not deploy or rollback without exact approval.

Mandatory policies:
- docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md
- persiantoolbox/docs/ops/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md

Hard rules:
1. Do not say fixed unless real browser tests pass.
2. Do not rely only on curl.
3. Do not claim Lighthouse scores unless you ran Lighthouse and captured output.
4. Do not hide failures.
5. Do not deploy, rollback, reload nginx, or change DNS without explicit approval phrase.
6. Do not commit secrets, browser cookies, private admin data, huge traces, or runtime dumps.

Phase 1 — Verify current GitHub state
In alirezasafaei-dev/persiantoolbox:
- confirm latest main contains the JS chunk copy fix
- inspect deploy-blue-green.sh and deploy-vps-auto.sh
- inspect scripts/deploy/post-deploy-verify.sh
- report whether post-deploy-verify is only curl/static checks or real browser verification
- report whether deploy-blue-green.sh actually invokes post-deploy-verify after cutover

Phase 2 — Live public checks, supporting evidence only
Run:
- bash scripts/deploy/post-deploy-verify.sh https://persiantoolbox.ir
- curl -I https://persiantoolbox.ir/
- curl -I https://persiantoolbox.ir/blog
- curl -I https://persiantoolbox.ir/api/ready
- check representative _next/static JS/CSS URLs from homepage HTML

These are not enough for success; they are only supporting checks.

Phase 3 — Real browser verification
Use Playwright from the project. The project already has Playwright dependencies/scripts.
Run a live browser audit against https://persiantoolbox.ir with:
- desktop Chromium
- mobile viewport
- console errors captured
- page errors captured
- failed network requests captured
- screenshots for P0/P1 failures
- JSON and Markdown report

Minimum live URLs:
- /
- /blog
- at least 10 blog post URLs from /blog
- /tools
- /loan
- /salary
- /check-penalty or the current check penalty route if different
- /base64 or current Base64 route if different
- JSON formatter route if present
- OCR route if present
- address converter route if present
- image tool route if present
- privacy/trust/about/contact/pricing/premium if present

Minimum interactions:
- click all desktop navbar links
- open/close mobile menu and click menu links
- open blog post cards
- test at least 5 tools with simple sample input and main action button
- verify theme toggle/dropdowns/buy buttons with real clicks if present

Phase 4 — Compliance gap check
The current script `scripts/deploy/post-deploy-verify.sh` is not policy-compliant if it only checks homepage/CSS/JS/API/fonts via curl.
If so, implement a proper browser-backed live verification wrapper such as:
- scripts/deploy/live-verify.mjs
- scripts/deploy/live-verify.sh
- package.json script `test:live`

The wrapper must output:
- LIVE_VERIFICATION_* verdict
- tested URL count
- browser/device list
- failed URLs
- console errors
- network failures
- screenshots/traces paths
- rollback target if known
- report file under reports/live-verification/ or docs/reports/live-verification/

Phase 5 — Deploy script integration
Refactor deploy-blue-green.sh and deploy-vps-auto.sh so they cannot print final deploy success unless live verification passes or clearly print:
DEPLOYED BUT LIVE VERIFICATION FAILED

The final line must not be `Deploy complete` unless live verification passed.

Phase 6 — Final report
Report:
- What MiMo got right
- What MiMo did not prove
- Whether live site is actually fixed
- Whether deploy verification is policy-compliant
- Files changed
- Tests run
- Browser evidence paths
- Remaining blockers
- Exact next safe action

Do not mark complete if real browser verification was not run.
```
