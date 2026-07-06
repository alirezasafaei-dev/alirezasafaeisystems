# Next Agent Prompt — Phase 2 Finance Pilot

**Status:** Active (post Phase 1)  
**PR handoff:** https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/42

Use this file or a matching PR comment. After execution, report on PR #42 and stop.

## Mission

Apply the Phase 2 high-value tool template to one finance surface and route qualified traffic to ASDEV Audit.

## Scope

- Repo: `persiantoolbox` only for code changes
- Tool: `/salary` hub (representative finance cluster)
- Reference: `docs/growth/HIGH_VALUE_TOOL_TEMPLATE.md`

## Tasks

1. Add contextual ASDEV Audit CTA using `tool-result-finance` placement / registry UTM pattern.
2. Keep it soft — no popups, no interruption of calculation flow.
3. Include sample-report + audit-start destinations.
4. Add or extend unit test if registry/CTA behavior changes.
5. Run: `pnpm typecheck`, `pnpm lint`, `pnpm test:ci || pnpm test`, `pnpm build`

## Out of scope

- New tools
- Billing / deploy
- Broad rollout to all tools

## Report

Comment on PR #42 with execution report. Then stop.