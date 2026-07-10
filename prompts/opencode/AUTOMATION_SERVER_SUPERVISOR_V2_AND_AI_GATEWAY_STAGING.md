# OpenCode Mission — Automation Supervisor v2 + AI Gateway Staging

RUN_CONTEXT: AUTOMATION_SERVER

You are OpenCode, the implementation agent for ASDEV. Execute this mission on `AUTOMATION_SERVER` only.

Canonical environments:

- `LOCAL_PC` = owner workstation; MiMo command center.
- `AUTOMATION_SERVER` = `asdev@91.107.153.223`; GitHub sync, supervisor, agent loop, MCP, Hermes/OpenClaw gateway, reports.
- `IRAN_PROD_SERVER` = live production server. Strictly forbidden in this mission.
- `GITHUB_MAIN` = authoritative source of truth.

Repository:

`/home/asdev/repos/alirezasafaeisystems`

GitHub repository:

`alirezasafaei-dev/alirezasafaeisystems`

Tracked issues:

- Issue #92 — Supervisor v2
- Issue #93 — AI Gateway staged installation

Primary mission:

1. Upgrade the Automation Server supervisor from detection-heavy v1 to policy-controlled, bounded, testable self-healing v2.
2. Stage the existing AI Gateway on `AUTOMATION_SERVER` in an installed, healthy, disabled state.
3. Do not enable AI Gateway automation.
4. Do not touch production.

## Hard prohibitions

- Do not SSH to or mutate `IRAN_PROD_SERVER`.
- Do not deploy any product.
- Do not change DNS, nginx, public edge, payment, database, production environment, or production secrets.
- Do not enable or start any AI Gateway timer/service.
- Do not create public AI chat functionality.
- Do not print, log, commit, or expose secrets.
- Do not commit `.env`, tokens, cookies, API keys, merchant IDs, private keys, browser profiles, HAR files, traces with credentials, database files, or production logs.
- Do not use `git reset --hard` against unknown/unpreserved work.
- Do not test recovery by breaking the active automation workspace.
- Do not claim PASS without commands, outputs, files, and report evidence.
- Do not stop after finding a blocker while safe work remains.

Actual AI Gateway activation requires exactly:

`APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT`

This phrase is not present in this prompt. Therefore activation is forbidden.

## Mandatory starting state capture

Run and record:

```bash
hostname
whoami
pwd
git status -sb
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git log --oneline -10
systemctl --user list-timers --all --no-pager
systemctl --user list-units 'asdev-*' --all --no-pager
```

Then:

```bash
cd /home/asdev/repos/alirezasafaeisystems
git fetch origin --prune
```

If the repo is clean and on `main`, fast-forward safely.

If it is dirty:

- classify every changed path,
- preserve legitimate work,
- do not overwrite unknown changes,
- generate a drift report,
- continue only where safe.

Create the working progress report immediately:

`docs/reports/automation-server/SUPERVISOR_V2_AND_AI_GATEWAY_STAGING_<UTC_TIMESTAMP>.md`

Update it throughout the mission.

# Phase 1 — Audit current supervisor and sync behavior

Inspect at minimum:

- `scripts/control-plane/asdev-supervisor.sh`
- `scripts/control-plane/install-asdev-supervisor.sh`
- `scripts/control-plane/sync-github-local-server.sh`
- `scripts/control-plane/loop-once.sh`
- related systemd user unit templates
- `.gitignore`
- latest supervisor/sync reports
- AI provider health/router scripts

Verify current claims rather than trusting documentation.

Record:

- current supervisor checks,
- current recovery actions,
- current lock behavior,
- timeout behavior,
- systemd allowlist behavior,
- MCP probe behavior,
- JSON generation method,
- report churn behavior,
- Git ignored/tracked artifact policy.

# Phase 2 — Implement Supervisor v2

## 2.1 Redirect-aware MCP health

Fix MCP health probing so that a healthy redirect does not produce a false warning.

Requirements:

- follow redirects with a bounded redirect count,
- use strict connect and total timeouts,
- record initial HTTP status, final HTTP status, and final URL where safe,
- distinguish DNS failure, connect failure, timeout, TLS error, redirect loop, and final HTTP failure,
- never classify HTTP `000` as PASS,
- do not expose request headers, cookies, authorization data, or tokens,
- handle SSE endpoints without waiting indefinitely for the stream.

A recommended approach is a short bounded request with `curl -L`, `--max-redirs`, `--connect-timeout`, `--max-time`, and safe output formatting. Validate behavior against the live MCP endpoint without mutating it.

## 2.2 Policy-controlled systemd recovery

Create an explicit allowlist for ASDEV user-level units only.

At minimum consider:

- `asdev-github-sync.timer`
- `asdev-agent-loop.timer`
- `asdev-health-monitor.timer`
- `asdev-mcp-monitor.timer`
- `asdev-supervisor.timer`
- corresponding services where appropriate
- `asdev-bot.service` only if that is the canonical installed name

Never mutate units outside the allowlist.

For allowlisted units:

- detect missing, disabled, inactive, and failed states separately,
- use `systemctl --user daemon-reload` only when justified,
- enable/start/restart only when policy permits,
- enforce cooldown and maximum retries,
- store repair state under ignored `.state/`,
- prevent restart storms,
- report each attempt and result,
- return `NO_GO` when a critical unit cannot be repaired.

Do not make system-wide changes. Do not use root units.

## 2.3 Concurrency and timeout safety

Add:

- a non-blocking `flock` lock,
- bounded command execution,
- clear behavior when another supervisor run is active,
- no overlapping repair attempts,
- no unbounded curl/systemctl/git command.

## 2.4 Robust JSON output

Current shell string interpolation can create invalid JSON when messages contain quotes, backslashes, or control characters.

Replace unsafe JSON construction with one of:

- `jq -n`, or
- a small Python serializer.

Requirements:

- output must parse successfully,
- all messages must be escaped safely,
- validation must run before reporting success,
- invalid JSON is a supervisor failure, not a silent warning.

## 2.5 Verdict semantics

Preserve and make explicit:

- `GO`
- `GO_WITH_WARNINGS`
- `NO_GO`

Add per-check statuses:

- `PASS`
- `WARN`
- `FAIL`
- `HEALED`

`NO_GO` must block task claiming in `loop-once.sh`.

## 2.6 Report retention and commit-churn control

Resolve the policy conflict between ignored raw automation logs and tracked summaries.

Required policy:

- raw logs remain local and ignored,
- durable human-readable summaries live under `docs/reports/automation-server/`,
- machine state lives under ignored `.state/`,
- repetitive timestamp-only changes must not create Git commits every few minutes,
- commits occur only when state meaningfully changes or a real incident/recovery occurs.

Implement deterministic normalization or change detection so identical healthy runs do not generate endless commits.

Do not blindly unignore the entire automation log directory.

# Phase 3 — Safe failure-injection tests

Perform tests only in disposable clones, temporary directories, mocked commands, or user-level isolated units.

Required scenarios:

1. MCP 307 redirect resolves to healthy final response.
2. MCP timeout produces WARN/FAIL, never PASS.
3. HTTP `000` cannot produce PASS.
4. Inactive allowlisted timer can be recovered safely.
5. Failed allowlisted service follows bounded retry/cooldown.
6. Non-allowlisted unit is never mutated.
7. Lock contention prevents overlapping execution.
8. Malformed provider state JSON is handled safely.
9. Detached HEAD is detected/recovered in a disposable clone.
10. Divergence is preserved with a recovery branch in a disposable clone.
11. Generated supervisor JSON validates.
12. `NO_GO` blocks the task loop.

Do not disable the active GitHub sync or agent loop merely to prove recovery.

# Phase 4 — Stage AI Gateway on AUTOMATION_SERVER

This phase is staging only.

## 4.1 Verify files and syntax

Verify:

- `scripts/ai-router/provider-health.sh`
- `scripts/ai-router/run-task.sh`
- `config/ai-providers.example.json`
- AI Gateway policy and registry docs
- sample task prompts

Run:

```bash
bash -n scripts/ai-router/provider-health.sh
bash -n scripts/ai-router/run-task.sh
python3 -m json.tool config/ai-providers.example.json >/dev/null
```

Run provider health using:

```bash
ASDEV_ENVIRONMENT=AUTOMATION_SERVER bash scripts/ai-router/provider-health.sh
```

Run router dry-runs using the actual CLI contract. Use `--help` first and record the supported syntax.

Validate from:

- repository root,
- a different working directory,
- relative task path,
- absolute task path.

No automatic execution is permitted.

## 4.2 Server configuration template

Create a safe staging configuration/template that contains no credentials.

Document:

- provider names,
- command availability checks,
- env-variable names only,
- capability classes,
- timeout policy,
- fallback order,
- circuit-breaker/cooldown behavior,
- task classes allowed on `AUTOMATION_SERVER`,
- task classes forbidden without approvals.

Explicitly block:

- production deploy,
- production rollback,
- migration,
- DNS/nginx/public-edge changes,
- production env mutation,
- secret rotation,
- destructive Git operations,
- payment mutation.

## 4.3 Disabled systemd unit templates

Prepare user-level templates for:

- `asdev-ai-gateway.service`
- `asdev-ai-provider-health.service`
- `asdev-ai-provider-health.timer`

Requirements:

- deterministic working directory,
- explicit `ASDEV_ENVIRONMENT=AUTOMATION_SERVER`,
- explicit PATH or executable paths,
- lock/concurrency protection,
- bounded runtime,
- safe restart policy,
- resource limits where sensible,
- `ConditionPathExists` guard,
- no Telegram polling,
- no conflict with Hermes reporting ownership,
- no production mutation capability,
- no embedded secrets.

Install templates only if the repository policy permits, but do not enable or start them.

At completion, prove:

```bash
systemctl --user is-enabled asdev-ai-gateway.service || true
systemctl --user is-active asdev-ai-gateway.service || true
systemctl --user is-enabled asdev-ai-provider-health.timer || true
systemctl --user is-active asdev-ai-provider-health.timer || true
```

Expected state:

- disabled or static as appropriate,
- inactive,
- no automatic task execution.

# Phase 5 — Validation

Run at minimum:

```bash
bash -n scripts/control-plane/asdev-supervisor.sh
bash -n scripts/control-plane/sync-github-local-server.sh
bash -n scripts/control-plane/loop-once.sh
bash -n scripts/ai-router/provider-health.sh
bash -n scripts/ai-router/run-task.sh
```

Also run:

- JSON validation for all generated state files,
- shellcheck if installed,
- systemd unit verification if available,
- existing repository tests relevant to control-plane/AI router,
- one real supervisor run,
- one real sync run only when repository state is safe,
- AI router dry-runs only.

After implementation, verify:

- branch is `main` or the chosen working branch,
- no detached HEAD,
- no divergence,
- no unknown dirty files,
- active automation units remain healthy,
- AI Gateway units remain inactive/disabled,
- no production systems were touched,
- no secrets were committed.

# Phase 6 — Git and issue workflow

Use logical commits, for example:

1. `fix(supervisor): make MCP health redirect-aware and reject HTTP 000`
2. `feat(supervisor): add allowlisted bounded systemd recovery`
3. `fix(supervisor): serialize valid JSON and suppress report churn`
4. `test(supervisor): add isolated recovery and failure-injection checks`
5. `feat(ai-gateway): add disabled AUTOMATION_SERVER staging units and docs`

Update Issues #92 and #93 with evidence.

Do not close an issue unless every acceptance criterion for that issue is actually satisfied.

Push safe commits to GitHub according to repository policy.

# Required final report

The report must include:

1. Executive verdict
2. Environment and Git state
3. Files inspected
4. Root causes found
5. Supervisor v2 changes
6. MCP redirect evidence
7. Systemd repair allowlist and cooldown behavior
8. JSON validation evidence
9. Failure-injection test matrix
10. AI Gateway provider health result
11. AI router dry-run results
12. Systemd staging unit state
13. Proof AI Gateway remains disabled/inactive
14. Tests and commands executed
15. Files changed
16. Commits created and pushed
17. Issue comments/closures
18. Remaining blockers
19. What was not tested
20. Exact next approval-gated action

Allowed final verdicts:

- `SUPERVISOR_V2_AND_AI_GATEWAY_STAGING_PASS`
- `SUPERVISOR_V2_PASS_AI_GATEWAY_STAGING_BLOCKED`
- `SUPERVISOR_V2_BLOCKED`
- `AI_GATEWAY_STAGING_BLOCKED`
- `INFRASTRUCTURE_NO_GO`

Never write “looks good”, “probably”, “should work”, or “done” without evidence.

Do not stop until all safe work is complete or the only remaining work requires an explicit approval or unavailable credential.