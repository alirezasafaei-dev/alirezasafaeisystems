# Codex Mission — Discover Final Completion

**Status:** ACTIVE  
**Mode:** YOLO + LOOP  
**Target:** finish `#182`, then close parent roadmap `#174` only with objective evidence.

## Mission

Own the remaining Discover Resource Hub work end-to-end. Do not wait for routine guidance and do not stop after analysis, a commit, PR, merge, or deploy. Continuously run:

`inspect → plan → execute → verify → fix → re-verify → next highest-value safe action`

Read and obey, in order: `AGENTS.md`, autonomous-loop/approval policies, the approved Discover spec + implementation plan, issues `#174/#182`, current `GITHUB_MAIN`, production evidence, and relevant code/tests. Treat repository and live evidence as truth, not prior agent claims.

## Operating contract

- Act as autonomous lead engineer. Make reasonable technical/product decisions yourself; ask no routine questions.
- Discover and invoke the strongest applicable skills/tools available. Use Superpowers workflows where relevant; use TDD, systematic debugging and verification-before-completion. Apply security, UI/UX, accessibility, SEO, performance, data/migration and deployment expertise as the work requires.
- Use parallel/sub-agents for independent investigations or reviews when this reduces risk or improves quality. Use the strongest available reasoning depth/model appropriate to each subtask.
- Prefer minimal, production-grade changes over new frameworks or speculative refactors. Follow existing architecture and governance.
- Never invent production content, URLs, Telegram handles/deep-links, credentials, test results or evidence. Never weaken security, tests, CSP, validation or approval gates to obtain green status.
- Exhaust authoritative repo/live/connected sources before declaring missing information. If a hard governance gate or genuinely unavailable authoritative external datum blocks one action, complete every other safe action and continue the loop instead of asking routine questions.

## Definition of Done

Finish the actual product, not just the code:

1. Establish and verify at least one **real, suitable published production Discover item** from authoritative existing data/content; validate its title, slug, useful guide and official destination. Use an exact Telegram message URL only when a real authoritative one exists/configured; never create a fake substitute.
2. Verify the full resource journey on production: `/discover`, `/en/discover`, real `/discover/[slug]` (and localized behavior), direct navigation + hard refresh, desktop + mobile, official CTA, conditional Telegram CTA, unpublished protection and Admin/API lifecycle.
3. Review resource-page quality as a senior UI/UX + SEO engineer: responsive layout, RTL/LTR, accessibility, metadata, canonical/hreflang, structured data where applicable, crawl/index behavior, content usefulness, performance and conversion hierarchy. Fix meaningful defects found within scope.
4. Verify telemetry/link integrity: intended Discover analytics fire, internal attribution remains correct, external/Telegram links are safe, and Telegram exact href receives no ASDEV UTM leakage.
5. Verify production data safety: snapshot/rollback posture, Prisma migration status, schema currency and zero drift. No destructive or guessed DB mutation.
6. Run the complete relevant quality stack on the exact implementation head: focused tests plus type-check, lint, full Vitest, build, Playwright smoke, a11y, security/high-critical audit and secret scan. Diagnose failures; do not bypass them.
7. Merge only verified changes. When governance permits deployment, deploy the exact intended SHA, then require smoke checks and **two consecutive live-browser verification passes**. Preserve evidence/artifacts and verify the live SHA/state rather than assuming CI success equals production success.
8. Update durable docs/memory/handoff and issues with exact facts: branch/head/merge/deploy SHAs, workflow IDs/URLs, migration state, live routes checked, evidence and any intentionally skipped conditional checks.
9. Close `#182` only when its acceptance criteria are objectively satisfied; then close `#174` only when the roadmap completion contract is satisfied. Never close either to make the dashboard look complete.

## Loop termination

Stop only when the Definition of Done is proven, or when repository governance requires a hard stop / security risk exists / exhaustive search proves no safe work remains. Final report must contain only verifiable facts under:

`STATUS · COMPLETED · CHANGES · TESTS · PR/MERGE SHA · DEPLOY SHA/WORKFLOW · LIVE EVIDENCE · ISSUES CLOSED · BLOCKERS · NEXT ACTION`
