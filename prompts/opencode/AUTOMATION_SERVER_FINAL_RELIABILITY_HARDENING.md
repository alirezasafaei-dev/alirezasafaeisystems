# OpenCode Mission — AUTOMATION_SERVER Final Reliability Hardening

## Run context

`AUTOMATION_SERVER`

Target host:

`asdev@91.107.153.223`

Target repository:

`/home/asdev/repos/alirezasafaeisystems`

GitHub source of truth:

`alirezasafaei-dev/alirezasafaeisystems` branch `main`

Primary GitHub issue:

`#94 — P1: Automation Server final reliability hardening — MCP validation, bounded recovery, commit throttling, reboot drill`

## Mission

Complete the final reliability hardening of the ASDEV automation server before AI Gateway automation rollout.

This is not a documentation-only exercise. Reproduce the remaining weaknesses, implement root-cause fixes, add regression tests, validate the real AUTOMATION_SERVER, commit and push safe changes, and update issue #94 with exact evidence.

Do not enable AI Gateway automation.
Do not touch IRAN_PROD_SERVER.
Do not deploy PersianToolbox.
Do not modify DNS, nginx, public edge, databases, payment configuration, or production environment variables.

## Current verified baseline

- Repository is on `main`.
- Detached HEAD is resolved.
- Recovery branches preserve previous divergent commits.
- GitHub sync v2 is active.
- Supervisor timer is active every 5 minutes.
- Latest supervisor report is `GO`, 13 PASS, 1 WARN, 0 FAIL.
- The remaining warning is MCP HTTP 307.
- Current supervisor code incorrectly treats HTTP `000` as PASS.
- Current divergence recovery can hard-reset unknown local divergence after creating a recovery branch.
- Runtime reports can create frequent timestamp-only commits.
- Controlled reboot persistence has not been proven.

Treat all baseline claims as untrusted until verified on the server.

## Non-negotiable safety rules

1. Work only on AUTOMATION_SERVER and the ASDEV mother repository.
2. Do not touch IRAN_PROD_SERVER.
3. Do not deploy or roll back any public product.
4. Do not enable AI Gateway automation.
5. Do not start a public AI product.
6. Do not print, log, commit, or expose secrets, tokens, cookies, private headers, credentials, `.env`, database files, traces, or private user data.
7. Do not hard-reset or delete unknown local code/config/script changes.
8. Do not automatically restart arbitrary systemd units.
9. Only restart explicitly allowlisted user units.
10. Use cooldowns and maximum retry counts to prevent restart storms.
11. Do not reboot without the exact owner approval phrase:

   `APPROVE_AUTOMATION_SERVER_REBOOT_DRILL`

12. Do not claim PASS without command output, file paths, commit SHAs, and generated reports.
13. Do not stop when one item is blocked. Mark it blocked and continue all safe work.
14. Do not ask the owner what to do next while safe work remains.
15. Do not hide warnings or downgrade failures to PASS.
16. HTTP `000` must never be treated as healthy.
17. Unknown code-bearing divergence must produce `NO_GO`, not an automatic reset.
18. AI Gateway rollout remains gated by:

   `APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT`

## Phase 0 — Reality check and evidence preservation

On AUTOMATION_SERVER run and record:

- `hostname -f`
- `whoami`
- `pwd`
- `git status -sb`
- `git branch --show-current`
- `git rev-parse HEAD`
- `git rev-parse origin/main`
- `git log --oneline -20`
- `git branch --list 'recovery/*'`
- `systemctl --user list-timers --all --no-pager`
- `systemctl --user list-units --all 'asdev-*' --no-pager`
- `loginctl show-user "$USER" -p Linger`
- disk, memory, load, and network state

Fetch origin safely. Do not mutate unknown dirty work.

Create a progress report immediately:

`docs/reports/automation-server/FINAL_RELIABILITY_HARDENING_<UTC_TIMESTAMP>.md`

Update the report throughout the mission.

## Phase 1 — MCP health check v2

Audit all current MCP health checks in:

- `scripts/control-plane/asdev-supervisor.sh`
- MCP monitor scripts
- systemd service/timer units
- operational docs

Implement a real MCP health validator.

Required behavior:

- bounded redirect following using `curl -L --max-redirs`
- strict connect timeout and total timeout
- TLS validation enabled
- capture initial status, redirect count, final URL, final status, content type, latency, and failure class
- validate the final SSE endpoint semantics using a safe lightweight handshake or content-type check
- redact query strings and sensitive headers from reports
- no credentials or cookies in command output

Classification policy:

- final healthy 2xx SSE response = PASS
- expected 307→healthy final SSE response = PASS
- HTTP 000 = FAIL
- DNS failure = FAIL
- TLS failure = FAIL
- connect timeout = FAIL
- total timeout = FAIL
- redirect loop/max redirects exceeded = FAIL
- final 4xx/5xx = FAIL, unless an explicitly documented authentication boundary makes a specific response expected
- empty/unparseable response = WARN or FAIL according to explicit policy

Never treat `000` as PASS.

Produce:

- machine-readable JSON state under `.state/`
- stable Markdown report under `docs/reports/automation-server/`
- tests using local mock HTTP/SSE fixtures for 200, 307→200, 000-equivalent connection failure, timeout, redirect loop, and 500

## Phase 2 — Supervisor v2 bounded self-healing

Identify the canonical user-unit names first. Do not guess.

Build an explicit allowlist for recoverable AUTOMATION_SERVER units. Candidate units include:

- `asdev-github-sync.timer`
- `asdev-github-sync.service`
- `asdev-agent-loop.timer`
- `asdev-agent-loop.service`
- `asdev-health-monitor.timer`
- `asdev-health-monitor.service`
- `asdev-mcp-monitor.timer`
- `asdev-mcp-monitor.service`
- `asdev-supervisor.timer`
- `asdev-supervisor.service`
- canonical Hermes reporting unit, only after verified discovery
- canonical MCP unit, only after verified discovery

Required recovery behavior:

1. Detect inactive, failed, missing, or flapping units accurately.
2. Restart only allowlisted units.
3. Use a per-unit cooldown.
4. Use maximum attempts in a rolling interval.
5. Persist recovery counters under `.state/`, not Git.
6. Re-check the unit after restart.
7. Record attempted, healed, still-failed, skipped-cooldown, skipped-not-allowlisted.
8. A critical unrecovered unit must produce `NO_GO`.
9. A non-critical warning may produce `GO_WITH_WARNINGS`.
10. Prevent the supervisor from restarting itself recursively or creating restart storms.

Do not restart production web services, databases, nginx, Docker workloads, or any IRAN_PROD_SERVER unit.

Add test fixtures or a safe mock layer proving:

- inactive allowlisted unit can be recovered
- non-allowlisted unit is refused
- cooldown works
- max-attempt limit works
- recovery re-check works
- critical unrecovered failure yields non-zero exit and `NO_GO`

## Phase 3 — Safer Git divergence policy

Audit sync and supervisor divergence handling.

Current unsafe pattern to eliminate:

- create recovery branch
- hard-reset to origin/main regardless of local commit contents

Implement classification before any reconciliation.

Classify local commits and dirty paths into:

### Generated-safe

Examples:

- approved runtime reports
- memory/status snapshots
- queue state
- explicitly allowed generated summaries

### Unknown/unsafe

Examples:

- scripts
- source code
- config
- systemd units
- workflows
- policy files not generated by the loop
- secrets or secret-like files
- databases and dumps

Required behavior:

- generated-safe divergence may be preserved and reconciled automatically under a documented method
- unknown/unsafe divergence must create a drift report and return `NO_GO`
- preserve exact local commit SHAs and changed file lists
- never delete local work merely because a recovery branch exists
- never silently resolve a code conflict
- never force-push
- never commit secret-like files

Add isolated Git fixture tests for:

- generated-only local ahead
- generated-only divergence
- code-bearing local ahead
- code-bearing divergence
- dirty unknown file
- detached HEAD
- stale rebase/cherry-pick/merge

## Phase 4 — Commit throttling and semantic-change detection

Eliminate commit storms caused by timestamp-only report updates.

Implement:

- stable semantic state signature/hash
- timestamp fields excluded from semantic comparison
- commit only when the health state meaningfully changes, a blocker appears/resolves, a recovery occurs, or the bounded interval expires
- default maximum one automated state commit per hour
- urgent severity transition may bypass throttle
- high-frequency raw state remains in `.state/` or ignored logs
- Git stores meaningful incident transitions, not every timer tick

Required counters:

- `skipped_no_semantic_change`
- `skipped_throttled`
- `committed_state_change`
- `committed_severity_transition`
- `commit_failed`

Required tests:

- identical semantic state with new timestamp does not commit
- changed warning/blocker state commits
- throttle blocks repeated non-urgent commit
- severity transition bypasses throttle
- state file remains valid JSON
- no secret-like path is staged

## Phase 5 — Loop integration

Verify `loop-once.sh` consumes supervisor verdict correctly.

Required behavior:

- `GO` → loop may continue
- `GO_WITH_WARNINGS` → loop may continue with warning report
- `NO_GO` → no task claim, no agent execution, no unsafe Git mutation
- supervisor failure itself must fail closed
- report exact reason for blocked loop

Add regression tests.

## Phase 6 — Reboot drill preparation

Prepare a complete runbook but do not reboot yet.

Required runbook:

- pre-reboot baseline
- backup/recovery branch verification
- connectivity expectations
- exact reboot command
- expected downtime
- post-reboot SSH retry strategy
- systemd linger verification
- timer/service verification
- Git branch/cleanliness verification
- MCP verification
- Hermes verification
- GitHub sync verification
- no restart-loop verification
- rollback/recovery steps if the server does not recover

The actual reboot is forbidden until the exact phrase is provided:

`APPROVE_AUTOMATION_SERVER_REBOOT_DRILL`

Without approval, final verdict must say:

`REBOOT_DRILL_PREPARED_NOT_EXECUTED`

This is acceptable and must not block completion of all other safe work.

## Phase 7 — Validation

At minimum run:

- `bash -n` on every changed shell script
- ShellCheck if available
- all new unit/fixture tests
- supervisor dry-run or test mode
- real supervisor run on AUTOMATION_SERVER
- real sync run on AUTOMATION_SERVER
- MCP validator against the real endpoint
- loop gate test
- Git status and divergence check
- systemd timer status

Required final server evidence:

- branch `main`
- origin reachable
- ahead/behind known
- no unknown dirty files
- no unknown divergence
- supervisor verdict
- MCP verdict
- timer states
- commit-throttle state
- AI Gateway remains disabled

## Phase 8 — GitHub delivery

- Keep commits logical and reviewable.
- Push safe changes to GitHub.
- Update issue #94 with progress and final evidence.
- Reference exact commit SHAs.
- Do not close issue #94 until all non-reboot acceptance criteria pass and reboot is either successfully executed after approval or explicitly recorded as prepared/gated.

Suggested commits:

1. `fix(mcp): validate redirects and SSE health without accepting HTTP 000`
2. `fix(supervisor): add bounded allowlisted service recovery`
3. `fix(sync): block unknown divergence and throttle generated commits`
4. `test(infra): add reliability regression fixtures`
5. `docs(ops): add automation server reboot drill runbook`

## Final report

Title:

`ASDEV AUTOMATION SERVER FINAL RELIABILITY HARDENING REPORT`

Required sections:

1. Executive verdict
2. Environment and SHAs
3. Baseline verification
4. MCP health evidence
5. Supervisor recovery evidence
6. Git divergence safety evidence
7. Commit-throttling evidence
8. Loop gate evidence
9. Tests executed
10. Files changed
11. Commits pushed
12. Systemd units changed
13. Remaining warnings
14. Reboot drill status
15. AI Gateway gate status
16. What was not tested
17. Exact next safe action

Allowed verdicts:

- `FINAL_RELIABILITY_PASS_REBOOT_GATED`
- `FINAL_RELIABILITY_PASS`
- `FINAL_RELIABILITY_WITH_WARNINGS`
- `MCP_HEALTH_BLOCKED`
- `SUPERVISOR_RECOVERY_BLOCKED`
- `GIT_SAFETY_BLOCKED`
- `COMMIT_THROTTLE_BLOCKED`
- `NO_GO`

Do not use vague phrases such as “looks good”, “probably fixed”, or “should work”.
Use only evidence-based statements.
