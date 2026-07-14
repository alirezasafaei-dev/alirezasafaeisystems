# AUTOMATION_SERVER P0 Real-Execution Recovery Mission

## Incident containment override — 2026-07-14

Before implementation:

- confirm `asdev-agent-loop.timer` is stopped under the Issue #45 Critical Guard;
- preserve and hash the current queue/state; reported pending volume is approximately 1050;
- do not execute, delete, or bulk-mark the backlog;
- implement a read-only duplicate classifier keyed by task ID plus normalized mission hash;
- treat repeated enqueue of identical missions as a failing regression fixture;
- do not re-enable the loop until the full real-worker contract, artifact validator, atomic state, report publication, and negative fixtures pass;
- first resumed cycle must execute at most one explicit contract-backed task.

Queue growth, service health, and acknowledgement comments are not completion evidence.


Status: executable P0 mission for Issues #98, #45, #94, #99, and #100.

## Operating mode

Act with high autonomy on `AUTOMATION_SERVER`, but fail closed. Do not ask for routine confirmations. Stop only for an explicit owner-approval gate, missing host access, missing short-lived credential, risk of data loss, or any required Production mutation.

Use the repository's latest `origin/main`. Create an isolated worktree and a fresh focused branch from current main. Never continue PR #107's branch and never target a non-main base.

## Primary outcome

Repair the ASDEV command bus and autonomous loop so a task can reach `done` only after:

1. a real allowlisted worker was invoked;
2. the declared repository/ref/SHA was used;
3. the worker returned a real exit status;
4. the declared artifact exists and is non-empty;
5. artifact schema/content validation passes;
6. the declared validation command passes;
7. evidence is persisted atomically;
8. report publication succeeds or the task remains incomplete.

Acknowledgement, log output, a generated timestamp, or a generic report is never completion evidence.

## Confirmed defects to address

- `run-autonomous-loop.sh` uses `local` outside a function in the Issue #45 path.
- `read-only`, `docs-only`, and `automation-script` currently succeed without invoking a worker.
- command-bus `RUN` ignores the requested mission and starts another generic loop.
- nested loop/command-bus invocation can recurse before command state is persisted.
- failures can be swallowed by `|| true` or converted into warning-only output.
- `collect-agent-report.sh` labels every report `Complete` without verifying execution.
- missing `node_modules` or `pnpm` can be reported as a skipped validation followed by success.
- network-offline paths may return success even when an assigned task was not executed.
- prompt/report timestamps and loose text matching are not a sufficient idempotency contract.
- state writes are not proven atomic and concurrent command consumption is insufficiently guarded.
- PR #107 targets the wrong base and still provides no real worker invocation.

## Mandatory task contract

Implement a machine-readable contract. JSON is preferred. Require at least:

`task_id`, `mission_file`, `worker_profile`, `repository`, `repo_path`, `base_ref`, `expected_sha`, `mode`, `expected_artifact`, `artifact_validator`, `validation_command`, `timeout_seconds`, `max_attempts`, `created_at`.

Reject unknown keys when safety-sensitive. Reject relative traversal, shell metacharacter injection, missing files, moving refs where an exact SHA is required, and commands not present in an explicit allowlist.

Do not use `eval`. Build command arguments as arrays. Redact environment and never print tokens, cookies, authorization headers, SSH material, database URLs, or provider secrets.

## Real worker dispatch

- Detect the canonical installed OpenCode executable/profile on AUTOMATION_SERVER.
- Invoke OpenCode for the declared mission with bounded timeout and captured stdout/stderr.
- Record executable path, safe version, worker profile, start/end time, exit code, repository, ref, exact SHA, artifact path, artifact hash, validator result, and validation result.
- Worker unavailable, timeout, non-zero exit, missing artifact, empty artifact, schema mismatch, repo mismatch, SHA mismatch, or validation failure must leave the task failed/retryable—not done.
- MiMo/Hermes may coordinate or report, but may not fabricate OpenCode execution evidence.
- One task may be claimed by only one worker. Use an atomic lock and an atomic state transition.

## Command bus requirements

- Persist command claim before execution to prevent recursion and duplicate consumption.
- Separate `claimed`, `running`, `validation`, `reporting`, `done`, and `failed` states.
- A nested invocation for the same comment/task must refuse execution.
- `[ASDEV RUN]` must resolve an explicit allowlisted contract or mission file; free-form shell execution is forbidden.
- Posting a status report is not equivalent to completing a task.
- Report-post failure must keep the task incomplete and retry safely without rerunning successful destructive work.
- Unknown authors/commands and stale comments must not execute.
- Preserve exact comment ID and task ID idempotently.

## Required regression fixtures

Create deterministic tests covering:

1. syntax of every changed shell script;
2. real fixture worker success plus valid artifact;
3. worker missing;
4. worker non-zero exit;
5. timeout;
6. artifact missing;
7. artifact empty;
8. invalid artifact schema;
9. wrong repository/ref/SHA;
10. validation command failure;
11. report publication failure;
12. duplicate comment/task;
13. nested command-bus recursion refusal;
14. stale lock recovery;
15. concurrent claim refusal;
16. offline before claim;
17. offline after successful worker but before reporting;
18. supervisor `NO_GO`;
19. disallowed mode/command;
20. secret-redaction canary;
21. generic acknowledgement cannot become done;
22. Issue #45 dry-run makes no GitHub API call.

Run `bash -n` and ShellCheck when available. Missing ShellCheck may be documented, but missing deterministic fixtures is a blocker.

## Real acceptance mission

After fixtures pass, execute exactly one real read-only OpenCode mission:

- repository: `alirezasafaei-dev/auditsystems`
- ref: current `main`
- baseline merge SHA of interest: `acc3f24488b1e4e6e3eb0bce232138c51bba42e0`
- purpose: post-merge security, migration, CI, privacy, lifecycle, and release-readiness review
- artifact: `docs/reports/automation-server/auditsystems-current-main-post-merge-review-<UTC>.md`

Artifact must include exact inspected SHA, P0/P1/P2 findings, file/line evidence, failure scenario, required fix, regression test, CI evidence assessment, and verdict `BLOCK_RELEASE` or `READY_FOR_LOCAL_DB_VALIDATION`.

Do not access Production DB. Do not deploy or migrate. Sanitized local/test PostgreSQL is allowed only if already provisioned and contains no Production data.

## Deliverables

- corrected scripts and tests;
- contract schema and example;
- updated ops documentation;
- one real worker evidence record;
- one validated post-merge review artifact;
- focused PR targeting current `main`;
- evidence comments on #98 and #45;
- update #94 only after #98 acceptance passes.

## Merge gate

Final verdict must be `BLOCK_MERGE` unless every fixture passes and the real OpenCode mission produces a validated artifact. Do not self-merge. Do not close #98 from acknowledgement-only evidence.

## Hard prohibitions

No Production deploy, Production database migration, payment activation, public pricing, outreach, DNS/nginx/firewall changes, reboot, AI Gateway rollout, IRAN_PROD access, force push, destructive reset, secret access, or deletion of user work.
