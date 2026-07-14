# AUTOMATION_SERVER — EXECUTE ISSUE #98 NOW

You are running on `AUTOMATION_SERVER`.

Do not summarize this file. Do not ask routine questions. Execute the steps below in order.

If a required command fails, record the command, exit code, and sanitized error. Fix it when safe. If it needs Production access, a secret value, a reboot, destructive cleanup, or owner authorization, stop and report `BLOCKED`.

## Fixed values

```text
MOTHER_REPO=alirezasafaei-dev/alirezasafaeisystems
MOTHER_REQUIRED_ANCESTOR=043415bd657f23679326e3d7aa8d163534d6c005
AUDIT_REPO=alirezasafaei-dev/auditsystems
AUDIT_MAIN_SHA=ac85316e77d499b04857b6845ddb943c9905bfeb
ISSUE=98
QUEUE_LAST_SEEN=1055 pending / 28 done
```

## Absolute rules

- Keep `asdev-agent-loop.timer` stopped and disabled.
- Do not execute, delete, reorder, mark, or rewrite the existing queue.
- Do not post `[ASDEV SAFE-MODE]`.
- Do not post a Critical Guard lift.
- Do not deploy, migrate, restart Production, access Production DB, change payment/pricing/DNS/nginx/firewall, reveal secrets, force-push, or reset destructively.
- Do not merge the PR you create.

## Step 1 — prove containment

Run:

```bash
systemctl --user stop asdev-agent-loop.timer
systemctl --user disable asdev-agent-loop.timer
systemctl --user is-active asdev-agent-loop.timer
systemctl --user is-enabled asdev-agent-loop.timer
systemctl --user list-timers --all | grep -F asdev-agent-loop || true
```

Required result:

```text
is-active = inactive
is-enabled = disabled
```

If either value differs, fix only this timer and repeat the proof. Do not continue while it can execute the queue.

## Step 2 — locate and snapshot the mother repository

Locate the existing mother clone. Set `MOTHER_ROOT` to its absolute path.

Verify:

```bash
git -C "$MOTHER_ROOT" remote -v
git -C "$MOTHER_ROOT" status --short
git -C "$MOTHER_ROOT" fetch --prune origin
git -C "$MOTHER_ROOT" merge-base --is-ancestor "$MOTHER_REQUIRED_ANCESTOR" origin/main
git -C "$MOTHER_ROOT" rev-parse origin/main
```

Do not modify or clean a dirty checkout.

Create a private incident snapshot directory with mode `0700`. Copy, without changing the originals:

- `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`
- agent-loop state directory
- command-bus state
- critical-guard state
- relevant user-level systemd unit files

Create SHA-256 hashes and a manifest containing paths, owners, modes, sizes, and hashes. Do not include environment values, tokens, cookies, SSH material, database URLs, or secret file contents in the report.

## Step 3 — verify the merged safety patch

From a clean checkout of `origin/main`, run:

```bash
bash -n scripts/agent-command-center/issue45-command-bus.sh
bash -n scripts/agent-command-center/tests/test-command-bus-guard.sh
bash scripts/agent-command-center/tests/test-command-bus-guard.sh \
  scripts/agent-command-center/issue45-command-bus.sh
```

Required final line:

```text
PASS: command bus guard/idempotency fixtures
```

Also verify that `critical-guard.json` reports `active: true`.

If the file is missing, first verify the deployed command bus contains `enforce_critical_guard`. Then run exactly this script once:

```bash
bash scripts/agent-command-center/issue45-command-bus.sh \
  45 alirezasafaei-dev/alirezasafaeisystems
```

The existing authorized Critical Guard comment must make it stop/disable the timer and exit before command intake. Confirm the guard state afterward. Do not run `run-autonomous-loop.sh`.

## Step 4 — create one isolated implementation worktree

Do not edit the deployed checkout.

Run equivalent commands:

```bash
UTC="$(date -u +%Y%m%dT%H%M%SZ)"
BRANCH="fix/p0-real-worker-contract-$UTC"
WORKTREE="$(dirname "$MOTHER_ROOT")/asdev-issue98-$UTC"
git -C "$MOTHER_ROOT" worktree add -b "$BRANCH" "$WORKTREE" origin/main
cd "$WORKTREE"
```

Record the exact base SHA.

## Step 5 — implement the real-worker contract

Inspect these files first:

```text
scripts/agent-command-center/run-autonomous-loop.sh
scripts/agent-command-center/issue45-command-bus.sh
scripts/agent-command-center/collect-agent-report.sh
scripts/control-plane/loop-until-blocked.sh
```

Implement these files or equivalent focused modules:

```text
scripts/agent-command-center/task-contract.schema.json
scripts/agent-command-center/dispatch-real-worker.sh
scripts/agent-command-center/validate-task-artifact.sh
scripts/agent-command-center/tests/test-real-worker-contract.sh
```

The task contract must require:

```text
task_id
mission_file
worker_profile
repository
repo_path
base_ref
expected_sha
mode
expected_artifact
artifact_validator
validation_command
timeout_seconds
max_attempts
created_at
```

Enforce all of the following:

1. No `eval`; build command arguments as arrays.
2. Allowlisted worker, mode, repository, and validation command only.
3. Reject path traversal, shell metacharacters, unknown safety-sensitive keys, wrong repository, wrong ref, and wrong SHA.
4. Detect the installed OpenCode executable with `command -v opencode`.
5. Read `opencode --help` and use its installed non-interactive invocation. Do not invent flags.
6. Apply a bounded timeout.
7. Capture real exit code, safe version, profile, start/end time, repository, ref, exact SHA, artifact path, SHA-256, validator exit, validation exit, and reporting result.
8. Require a non-empty artifact.
9. Write state atomically using a temporary file plus rename.
10. Use exactly these states:

```text
claimed -> running -> validation -> reporting -> done
                                      \-> failed
```

A task must remain `failed` or incomplete when any of these occurs:

- worker missing;
- worker exits non-zero;
- timeout;
- missing or empty artifact;
- invalid artifact;
- wrong repository/ref/SHA;
- validation failure;
- report publication failure;
- supervisor `NO_GO`;
- duplicate, concurrent, stale, or recursive claim.

Acknowledgement text, logs, timestamps, queue comments, or service health are never proof of completion.

## Step 6 — implement deterministic tests

Use a fake worker for fixtures. The fake worker must write controlled artifacts and controlled exit codes.

Tests must cover all 22 cases:

1. syntax;
2. success with valid artifact;
3. worker missing;
4. worker non-zero;
5. timeout;
6. artifact missing;
7. artifact empty;
8. invalid schema;
9. wrong repository/ref/SHA;
10. validation failure;
11. report publication failure;
12. duplicate comment/task;
13. nested command-bus recursion;
14. stale-lock recovery;
15. concurrent claim;
16. offline before claim;
17. offline after worker success and before reporting;
18. supervisor `NO_GO`;
19. disallowed command/mode;
20. secret-redaction canary;
21. acknowledgement cannot become `done`;
22. Issue #45 dry-run performs no GitHub mutation.

The tests must not call the real GitHub API and must not touch the real queue or real user services.

Run:

```bash
for file in scripts/agent-command-center/*.sh; do bash -n "$file"; done
for file in scripts/agent-command-center/tests/*.sh; do bash -n "$file"; done
bash scripts/agent-command-center/tests/test-command-bus-guard.sh \
  scripts/agent-command-center/issue45-command-bus.sh
bash scripts/agent-command-center/tests/test-real-worker-contract.sh
```

Run ShellCheck if installed. A missing ShellCheck binary may be reported. Any missing or failing fixture is `BLOCK_MERGE`.

## Step 7 — execute exactly one real acceptance task

Do this only after every fixture passes. Keep the queue timer disabled.

Locate the existing AuditSystems clone and set `AUDIT_ROOT` to its absolute path. Then create a detached read-only worktree at the exact commit:

```bash
git -C "$AUDIT_ROOT" fetch --prune origin
git -C "$AUDIT_ROOT" cat-file -e \
  ac85316e77d499b04857b6845ddb943c9905bfeb^{commit}
AUDIT_WORKTREE="$(dirname "$AUDIT_ROOT")/auditsystems-review-$UTC"
git -C "$AUDIT_ROOT" worktree add --detach "$AUDIT_WORKTREE" \
  ac85316e77d499b04857b6845ddb943c9905bfeb
test "$(git -C "$AUDIT_WORKTREE" rev-parse HEAD)" = \
  "ac85316e77d499b04857b6845ddb943c9905bfeb"
```

Create one contract that invokes the real installed OpenCode worker to inspect that checkout.

Mission:

```text
Review AuditSystems main for security, privacy, migration safety, lifecycle integrity,
CI truth, and release readiness. Do not modify AuditSystems. Do not access Production.
```

Required artifact inside the mother implementation worktree:

```text
docs/reports/automation-server/auditsystems-current-main-post-merge-review-<UTC>.md
```

Required artifact sections:

```text
# AuditSystems Current-Main Review
## Inspected SHA
## Worker Evidence
## P0 Findings
## P1 Findings
## P2 Findings
## CI Evidence
## Required Regression Tests
## Verdict
```

The verdict must be exactly one of:

```text
BLOCK_RELEASE
READY_FOR_LOCAL_DB_VALIDATION
```

Validate the artifact and record its SHA-256. Publish a sanitized acceptance report to mother Issue #98. Report publication is part of this task: the state may reach `done` only after the worker, artifact, validator, validation command, atomic evidence write, and Issue #98 publication all succeed.

If the real worker cannot run, stop with `BLOCKED_REAL_WORKER`. Do not fabricate the artifact.

## Step 8 — commit, push, and open a draft PR

Before committing:

```bash
git status --short
git diff --check
```

Commit only focused #98 implementation, tests, documentation, and the validated acceptance artifact.

Push the new branch and open a draft PR targeting current mother `main`.

PR title:

```text
fix(automation): require real worker and validated artifact before completion
```

PR body must include:

- exact base/head SHA;
- changed files;
- all commands and exit codes;
- fixture count and results;
- real OpenCode invocation class and safe version;
- AuditSystems exact SHA;
- artifact path and SHA-256;
- validation result;
- timer inactive/disabled proof;
- safety boundaries;
- verdict `BLOCK_MERGE` or `READY_FOR_REVIEW`.

Do not merge it.

Post sanitized evidence to mother Issues #98 and #45. Do not post ASDEV RUN, SAFE-MODE, or guard-lift commands.

## Final response format

Return only this structure:

```text
STATUS: READY_FOR_REVIEW | BLOCK_MERGE | BLOCKED
MOTHER_BASE_SHA:
BRANCH:
PR_URL:
TIMER_ACTIVE:
TIMER_ENABLED:
QUEUE_MUTATED: no
WORKER_EXECUTABLE:
WORKER_VERSION:
WORKER_EXIT_CODE:
AUDIT_SHA:
ARTIFACT_PATH:
ARTIFACT_SHA256:
FIXTURES_PASSED: <number>/22
VALIDATOR_EXIT_CODE:
VALIDATION_EXIT_CODE:
REPORT_PUBLISHED: yes|no
VERDICT:
BLOCKERS:
```

Do not return `READY_FOR_REVIEW` unless all 22 fixtures pass and the one real acceptance task produces and validates the required artifact.
