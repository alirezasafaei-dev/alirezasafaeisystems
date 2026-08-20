# Codex Mission — Discover v2 Completion

**Status:** ACTIVE  
**Tracker:** #189  
**Related growth loop:** #188  
**Mode:** YOLO + LOOP  
**Autonomy:** MAXIMUM WITH GOVERNANCE GATES

## Objective

Execute the owner-approved Discover v2 design and implementation plan end-to-end, using the existing ASDEV architecture, until every safe Definition-of-Done item is objectively proven. Do not stop after analysis, one task, one PR, one merge, one publication or partial verification.

Continuous loop:

`inspect → plan/ledger → implement → test → review → fix → verify → next highest-value safe action`

## Required reading order

1. `AGENTS.md`
2. `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`
3. `docs/governance/APPROVAL_GATES.md`
4. `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md`
5. `docs/superpowers/specs/2026-08-20-discover-v2-admin-localization-seo-automation-design.md`
6. `docs/superpowers/plans/2026-08-20-discover-v2-admin-localization-seo-automation.md`
7. Issue `#189` including the explicit owner design approval comment
8. Issue `#188` only for growth-loop context; do not conflate its completion with #189
9. Current `GITHUB_MAIN`, current production evidence and relevant existing Discover code/tests

The approved spec is binding. The implementation plan is its execution argument. Repository governance overrides both for security/production gates.

## Required execution method

Use Superpowers `subagent-driven-development` as the default execution method and create/verify an isolated worktree before implementation. Maintain the plan-specific SDD ledger so work can resume safely after context loss.

Per task:

1. dispatch a fresh implementer subagent with explicit model choice;
2. use test-driven development for behavior changes;
3. run the task's focused tests;
4. dispatch a separate task reviewer for spec compliance + code quality;
5. fix findings and re-review;
6. record commit/evidence in the ledger;
7. continue automatically to the next task.

For bugs/test failures, use systematic debugging before proposing fixes. Before any completion claim, use verification-before-completion. Before merge/final handoff, run a whole-branch code review with the strongest appropriate reviewer.

Do not ask routine questions. Make reversible engineering rulings against the approved spec and record them. Stop only for a real governance/security/destructive hard gate or if every forward path would be guesswork.

## UI UX Pro Max requirement

Task 1 must vendor the open-source UI UX Pro Max core skill from exactly:

- upstream: `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`
- commit: `bc826e2267a36d98a2dcf5231e16c30ff546770f`
- license: MIT

Vendor it locally under `.agents/skills/ui-ux-pro-max/` with license, upstream provenance and deterministic checksums. Do not globally install it and do not add it as a runtime dependency.

Use its repository-local Python standard-library search flow for Admin, landing and detail design decisions. Persist the selected Discover design system in-repo. Treat the generated guidance as advisory; accessibility, project governance and approved product constraints remain authoritative.

## Non-negotiable product contracts

- Persian navbar label for `/discover`: **`ابزارها و منابع`**.
- Persian category labels are localized; canonical DB keys are not visible display copy.
- Existing Persian/base content remains backward compatible.
- English resource pages are public/indexable only with complete English content and `publishedEn=true`; do not publish Persian fallback as an English SEO page.
- Admin is Persian-first RTL; slug/URL/identifier and English fields are semantic LTR.
- Keep one existing Admin/API/Prisma/analytics platform. No parallel CMS/service/worker/database.
- Ordinary resource additions remain zero-deploy.
- No Meta API, Instagram scraping dependency, ManyChat, Zapier, Make, paid design/AI service or runtime SaaS dependency for the core workflow.
- No ASDEV UTM leakage to external, Telegram or Instagram destinations.
- Never invent URLs, Telegram handles/message links, translations, service claims, analytics or evidence.

## Automation target

Complete deterministic self-hosted automation from:

`verified source/evidence → resource JSON manifest → local validation → Admin JSON import/review → authenticated save/publish → FA/EN route + sitemap + SEO + telemetry verification`

Production content remains the database Source of Truth. Repository manifests are review/import artifacts only and never bypass authentication or server-side validation.

## Acceptance resource

Use `deepseek-telegram-bot` as the real end-to-end acceptance item.

Verified identity contract:

- Telegram handle: `@deepseek_gidbot`
- resource destination: `https://t.me/deepseek_gidbot`
- source Reel: `https://www.instagram.com/p/Db9O3I-M6Dy/`
- third-party operator context: G.Media
- must visibly state it is **not the official DeepSeek bot**
- `telegramGuideUrl` remains empty unless an exact authoritative ASDEV message-level tutorial/file link exists
- do not claim permanent unlimited usage; first-hand ASDEV test observations must remain framed as observations

Existing resource design/evidence file may be consulted if present, but normalize the final manifest to the v2 schema/category contract.

## Required verification stack

At minimum before a runtime PR is considered ready:

```bash
pnpm lint
pnpm type-check
pnpm test
pnpm build
pnpm discover:validate
pnpm test:e2e:smoke
pnpm test:e2e:a11y
pnpm exec playwright test e2e/discover-v2.spec.ts
pnpm lighthouse:ci
pnpm audit:high
pnpm scan:secrets
```

Run exact-head CI/security checks and resolve failures before merge.

## Production gates — DO NOT BYPASS

The owner approval of Spec #189 is design approval only.

If repository governance requires either of these exact phrases, stop only at that gate and request the phrase exactly:

- `APPROVE_CRITICAL_SITE_MIGRATION`
- `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`

Do not treat `approved`, `go ahead`, `YOLO`, `merge it`, or the Spec #189 approval as substitutes.

If merging to `main` would automatically trigger a gated production deployment, do not merge until the corresponding exact production gate is satisfied. Continue every other safe task first: implementation, tests, review, PR preparation, migration dry-run, evidence preparation and issue updates.

## Production completion evidence

After required gates are explicitly satisfied:

1. deploy only the exact reviewed/merged SHA;
2. capture release id, backup/snapshot and rollback target;
3. verify migration count/status and zero schema drift;
4. verify `/api/ready` and health;
5. use authenticated Admin to prove the Discover editor and publish/import workflow;
6. publish the DeepSeek acceptance resource through the ordinary Admin/API path;
7. run two consecutive live Chromium passes on desktop and mobile;
8. verify Persian and any legitimately published English route, sitemap, canonical/hreflang/structured data, CTA destination semantics and no UTM leakage;
9. verify consent-aware Discover telemetry end-to-end;
10. archive exact evidence in durable docs and Issue #189.

Do not require `/en/discover/deepseek-telegram-bot` to exist if reviewed English editorial content was intentionally not published. In that case, verify that the English detail is absent from public resolution and sitemap as designed.

## Completion rule

Close #189 only when the approved design and implementation plan are objectively complete in production with exact live evidence and ordinary future resource publishing remains zero-deploy.

Do not close #188 merely because #189 is complete; #188 has a separate ongoing growth-loop Definition of Done.

## Final report format

`STATUS · PLAN TASKS · UI UX SKILL · ADMIN · I18N · DISCOVER LANDING · DETAIL · SEO · AUTOMATION · ACCEPTANCE RESOURCE · TESTS · CI/SECURITY · MIGRATION · DEPLOY SHA/RELEASE · LIVE EVIDENCE · ISSUE #189 · BLOCKERS · NEXT GROWTH ACTION`
