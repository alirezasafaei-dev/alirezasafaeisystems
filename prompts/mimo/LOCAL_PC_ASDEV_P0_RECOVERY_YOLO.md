# LOCAL_PC MiMo P0 Recovery — High-Autonomy YOLO Mission

## Final containment command — 2026-07-14 (supersedes every older sequence below)

### Verified GitHub/server evidence

- Mother command-bus containment PR #112 is merged at `043415bd657f23679326e3d7aa8d163534d6c005`.
- Issue #45 later posted `ASDEV stopped`; treat `asdev-agent-loop.timer` as disabled until locally proven otherwise.
- Last pre-STOP queue evidence is `1055 pending / 28 done`. Preserve it as incident evidence. It is not an execution backlog.
- AuditSystems workflow-hardening PR #45 is merged at `ac85316e77d499b04857b6845ddb943c9905bfeb`.
- AuditSystems security PR #46 is open at `54e6f7c008b26df2dc804d81c761e456e4517630` and is BLOCK_MERGE.
- Mother CI PR #109 is Draft at `f20b0e26e1d1c87406d3d95673c328870b858f32` and is BLOCK_MERGE.
- Current CI truth: mother workflows fail before usable execution evidence; AuditSystems main-gate/roadmap jobs queue, and docs can fail with zero recorded steps.

### Execute now, in this exact order

1. Stop and disable only `asdev-agent-loop.timer` again idempotently. Do not stop repository sync, reporting, or supervision unless their own evidence proves unsafe.
2. Hash and copy queue/state/service definitions to a timestamped local incident directory. Record paths, owners, modes, hashes, and counts. Never print secrets.
3. Fetch mother `origin/main`; prove commit `043415b` is present. Inspect the deployed `issue45-command-bus.sh` and run:
   - `bash -n scripts/agent-command-center/issue45-command-bus.sh`
   - `bash scripts/agent-command-center/tests/test-command-bus-guard.sh scripts/agent-command-center/issue45-command-bus.sh`
4. Prove timer state with `systemctl --user is-active`, `is-enabled`, `list-timers`, and recent sanitized journal lines. Require inactive + disabled.
5. Build a read-only duplicate report for the 1055-item queue keyed by exact task ID and normalized mission hash. Do not mutate the source queue.
6. Recover the existing isolated `asdev-mother-ci` and `asdev-audit-ci` runners in place. Inspect service identity, runner version, workspace ownership, Git safe-directory, disk/temp, DNS/TLS, and GitHub action endpoints. Do not register duplicates unless stored identity is missing or corrupt.
7. Produce a fresh checkout reproduction with non-expired logs. Fix the root cause without weakening `actions/checkout`, permissions, pinning, or repository isolation.
8. Run current PR #109 and PR #46 heads. Require non-empty steps, exact head SHA, frozen install, typecheck, lint, complete tests, build, smoke where declared, and cleanup. Do not merge either PR unless all gates pass.
9. Repair #98 from current mother main in an isolated worktree. Accept only real worker exit code + non-empty validated artifact + validation command + atomic state + successful report publication.
10. Keep the Critical Guard active. Do not post `[ASDEV SAFE-MODE]` or a guard-lift marker. After #98 passes, prepare a proposed one-task resume dossier and stop for owner approval before enabling the timer.

### Aggressive mode rule

Do not wait after a failed command. Capture exit code and sanitized evidence, isolate the cause, apply the smallest reversible fix, rerun the exact failing check, and continue. Never convert missing evidence into PASS. Never touch Production, Production data, payment, pricing, DNS/nginx, public outreach, or secrets.


## Operational override — 2026-07-14

This section supersedes any older sequencing in this document.

### Confirmed current state

- Automation Server queue reported approximately 1050 pending items and repeated duplicate enqueue events.
- A `[ASDEV STOP]` containment command and Critical Guard were posted to Issue #45.
- #98 has partial fixes for the top-level `local` crash and RUN lock recursion, but still has no real-worker/artifact acceptance.
- Mother CI PR #109 is Draft, CI-only, current head `f20b0e26e1d1c87406d3d95673c328870b858f32`, and blocked by offline `asdev-mother-ci`.
- AuditSystems PR #45 contains runner workflow hardening and is blocked by offline `asdev-audit-ci`.
- AuditSystems PR #46 contains security fixes plus route tests added in commits `4f9de767` and `61637e55`; it is also blocked by the offline audit runner.

### Mandatory first actions

1. Confirm `asdev-agent-loop.timer` is inactive. If still active, stop only this timer. Keep GitHub sync and supervisor available.
2. Snapshot the queue and state files with hashes. Do not execute or delete the backlog.
3. Build a dry-run queue classifier that groups exact duplicate task IDs and normalized mission hashes, separates unique tasks, and reports counts without mutation.
4. Repair #98 fully before queue cleanup or resumption.
5. Recover the two existing dedicated runners under their existing isolated accounts; do not register duplicates unless the existing identity is missing/corrupt.
6. Run PR #109, PR #45, and PR #46 with real non-empty CI steps.
7. Execute the new PR #46 focused tests locally before waiting for runner CI.
8. Only after #98 passes, create a preserved queue checkpoint, deduplicate by exact identity, and re-enable with `[ASDEV SAFE-MODE]`.
9. Resume at most one contract-backed task. Verify worker, artifact, validator, state, and report evidence before releasing additional work.

The 1050-item backlog is not authorization to execute 1050 tasks. Queue volume is an incident to diagnose.


You are the primary LOCAL_PC commander for ASDEV. Operate in high-autonomy, non-interactive, evidence-first mode. Move fast, inspect deeply, fix root causes, and finish every safe reversible action that is in scope. Do not stop after analysis or produce acknowledgement-only reports.

“YOLO” here means maximum initiative inside the safety boundary—not bypassing permissions, hiding failures, weakening checks, destroying work, or touching Production without approval.

## Repositories

- mother/governance/site: `alirezasafaei-dev/alirezasafaeisystems`
- audit product: `alirezasafaei-dev/auditsystems`

Start from fresh fetches. Record current `origin/main` SHAs. Preserve all existing dirty work and unknown branches. Use isolated worktrees for every write mission. Never use destructive reset, force push, broad cleanup, or secret-printing commands.

## Mission priority

Execute the following dependency chain aggressively:

1. restore trustworthy self-hosted CI in the mother repository;
2. prove AuditSystems `main-gate` runs with real steps on current main;
3. repair ASDEV real-worker execution under #98;
4. run a current-main post-merge security/release review of AuditSystems;
5. prepare, but do not execute, Production release #103;
6. clean stale GitHub trackers and publish exact evidence.

Do not start P1 product breadth while any P0 gate is red.

## Phase 0 — safety and state capture

- inspect both repositories, branches, worktrees, remotes, dirty paths, hooks, Node/pnpm versions, disk, runner accounts, runner process state, and non-secret service status;
- confirm dedicated runner users cannot access Docker socket, sudo, SSH keys, Production env, DB/payment secrets, or shared agent credentials;
- record only variable names when needed—never values;
- fetch current Issues #98, #102, #103, #105 and PRs #107 and #109;
- verify PR #109 targets current main and contains only the intended CI workflow change;
- classify all unexpected divergence and stop only if preservation cannot be guaranteed.

## Phase 1 — mother CI PR #109

Take ownership of PR #109.

- validate workflow YAML locally;
- enforce same-repository PR execution only;
- keep `permissions: contents: read`;
- keep immutable action SHAs;
- use the isolated `asdev-mother-ci` runner only;
- do not expose Docker/sudo/Production secrets;
- run frozen install, secrets scan, type-check, lint, tests, build, enterprise gate, and browser smoke;
- ensure cleanup runs on success and failure;
- diagnose why the CI workflow is not visible or does not dispatch;
- fix branch triggers, workflow syntax, Actions settings, runner labels, offline runner state, or network routing as required;
- capture a real run URL with non-empty steps;
- perform a deliberate-failure proof on a temporary commit, verify exact failure step, revert it, and prove recovery success;
- post evidence to PR #109, #102, and #105;
- do not merge unless the full gate is green and scope is clean.

Existing GitHub-hosted PR workflows may continue to fail before steps due billing. Do not waste cycles rerunning them. Their impossible hosted checks should be retired, migrated, or made non-required through a focused reviewed change—not silently ignored.

## Phase 2 — AuditSystems CI truth

On current AuditSystems main:

- verify runner `asdev-audit-ci` is online and isolated;
- trigger `main-gate` on current main;
- require real steps and logs, not `cancelled`, `steps: []`, or PR-body claims;
- run secrets scan, pinned-action check, automation hard gate, build, readiness smoke, and artifact upload;
- diagnose cancellation, concurrency, offline runner, stale processes, network receiver timeouts, cache corruption, or workflow trigger errors;
- keep deploy/payment/docs-write workflows separate;
- post exact head SHA, run URL, test count, build result, artifact result, and cleanup evidence to AuditSystems #41 and mother #102/#105;
- reopen or replace a tracker if #41 was closed without meeting its stated acceptance.

## Phase 3 — #98 real execution repair

Treat PR #107 as rejected design evidence. Do not merge it. Work from current mother `origin/main`.

Use:
`prompts/opencode/AUTOMATION_SERVER_P0_REAL_EXECUTION_RECOVERY.md`

Connect to AUTOMATION_SERVER only through the owner's existing secure SSH configuration. Do not print host addresses, credentials, tokens, environment values, or shell history.

Inspect and repair:

- invalid top-level `local`;
- acknowledgement-only success paths;
- command-bus recursion and duplicate consumption;
- ignored `[ASDEV RUN]` mission arguments;
- swallowed exit codes;
- unconditional `Status: Complete` reports;
- missing artifact/validator contract;
- non-atomic state transitions;
- report publication failure behavior;
- supervisor `NO_GO` fail-closed integration.

Require all deterministic fixtures plus one real OpenCode read-only mission and validated artifact. Create a focused PR from current main. Never merge merely because syntax tests pass.

## Phase 4 — post-merge AuditSystems review

Inspect current main, including merge `acc3f24488b1e4e6e3eb0bce232138c51bba42e0`.

Review:

- Prisma migration on clean and legacy PostgreSQL fixtures;
- enum conversion and timestamp preservation;
- CSRF on every admin mutation;
- consent never inferred;
- duplicate lead privacy;
- terminal lifecycle downgrade prevention;
- order retry and one-to-many relation correctness;
- capture only after successful audit;
- analytics failure isolation;
- queue/start/retry idempotency;
- admin non-2xx handling;
- English/Persian qualification routes;
- secret scan fail-closed behavior;
- immutable action pins;
- real CI evidence;
- release rollback feasibility.

Produce file/line evidence, regression tests, and verdict `BLOCK_RELEASE` or `READY_FOR_LOCAL_DB_VALIDATION`. Fix safe code defects in isolated branches with focused PRs. Do not modify Production data.

## Phase 5 — release #103 preparation only

Prepare a signed release dossier for current main SHAs:

- merge ancestry;
- frozen local acceptance;
- isolated PostgreSQL migration rehearsal;
- backup and restore-verification commands;
- ordered AuditSystems-first deployment runbook;
- worker/web restart commands from existing runbooks;
- smoke matrix for health, readiness, qualification, sample report, CSRF, lead lifecycle, attribution, Persian/English, mobile/desktop;
- test-data cleanup;
- rollback triggers and exact rollback steps;
- final preflight verdict.

Do not deploy, migrate Production, restart Production services, access Production DB, change DNS/nginx, activate payment, publish pricing, or send outreach. Stop at the explicit owner approval gate.

## Phase 6 — GitHub hygiene

- close obsolete PR #104 with a superseded explanation;
- keep PR #107 closed/rejected unless replaced by a correct current-main PR;
- re-scope or close #99/#100 because their original PR heads have already merged;
- ensure new reviews target current main SHAs;
- correct stale documentation only in focused commits;
- do not mix generated reports, CI changes, product changes, and automation changes in one PR.

## Reporting contract

Every report must contain:

- environment;
- repository;
- branch;
- exact base/head SHA;
- commands executed;
- exit codes;
- changed files;
- tests and counts;
- workflow run URLs;
- artifacts and hashes;
- blockers;
- safety boundaries;
- verdict;
- next executable action.

Never write `PASS`, `Complete`, `READY`, or `done` without direct evidence.

## Stop conditions

Stop and request the owner only for:

- short-lived runner registration token entry;
- unavoidable Production mutation;
- reboot;
- data-loss risk;
- unavailable secure host access;
- conflicting unknown user work that cannot be preserved;
- payment/pricing/outreach authorization.

Everything else: inspect, implement, test, document, open focused PRs, and publish evidence automatically.
