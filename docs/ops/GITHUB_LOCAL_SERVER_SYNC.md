# GitHub / Local / Server Sync Operating Model — ASDEV

**Status:** Mandatory operating model  
**Policy dependency:** `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`

## Goal

GitHub, `LOCAL_PC`, and `AUTOMATION_SERVER` must stay synchronized without routine manual intervention.

The owner should be able to commit a prompt/policy/queue update to GitHub and expect `AUTOMATION_SERVER` to pull it, discover it, and act on safe tasks automatically.

## Environments

- `LOCAL_PC`: owner workstation, high-context command center.
- `AUTOMATION_SERVER`: `asdev@91.107.153.223`, always-on agent loop and GitHub sync.
- `IRAN_PROD_SERVER`: production deployment server, not an auto-sync execution target for production mutations.

## Source of truth

- GitHub `main` is the source of truth.
- Local or server changes are temporary until committed and pushed.
- Dirty local/server state must be reported, not silently overwritten.

## Sync levels

### Level 0 — Read-only status

Only report:

- branch
- local HEAD
- origin/main HEAD
- dirty state
- ahead/behind/diverged state

### Level 1 — Safe pull

Allowed when the repo is clean:

```bash
git fetch origin
git pull --rebase origin main
```

### Level 2 — Safe report commit

Allowed for generated docs/reports/state only:

- `docs/reports/**`
- `reports/**`
- `ops/automation-logs/*.summary.md` if explicitly safe
- `docs/memory/**` when it does not contain secrets
- `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`
- `control-plane/queue/queue.json`

### Level 3 — Code/script mutation

Allowed only as a normal safe automation task, with tests and reports.

### Level 4 — Production mutation

Always gated. Not part of sync automation.

## Dirty-state policy

If dirty files exist:

1. Classify changed paths.
2. If all changes are safe generated reports/state, commit them with `[skip ci]` when appropriate.
3. If changes include code/scripts/config/secrets/unknown files, do not reset.
4. Write drift report.
5. Continue non-destructive health checks.

## Required service/timer

`AUTOMATION_SERVER` must run:

- `asdev-github-sync.service`
- `asdev-github-sync.timer`

Target interval: every 5 minutes. 10 minutes is acceptable if server load requires it.

The timer must:

- survive logout via user linger
- use `flock` to prevent overlap
- timeout safely
- write logs
- not stop the main agent loop if GitHub is down

## Required script

Canonical script:

```text
scripts/control-plane/sync-github-local-server.sh
```

Run examples:

```bash
ASDEV_ENVIRONMENT=AUTOMATION_SERVER scripts/control-plane/sync-github-local-server.sh
ASDEV_ENVIRONMENT=LOCAL_PC scripts/control-plane/sync-github-local-server.sh
```

## Required outputs

The script must write:

```text
.state/asdev-sync/latest.json
ops/automation-logs/github-sync-latest.log
docs/reports/automation-server/latest-github-sync.md
```

Large raw logs should not be committed unless explicitly safe. Summary reports may be committed.

## Prompt and queue discovery

After successful pull, automation must verify:

- `prompts/opencode/*.md` exists when referenced by queue
- `prompts/local/*.md` exists when referenced by queue
- `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` is readable
- `control-plane/queue/queue.json` is valid JSON

If a referenced prompt is missing locally:

1. fetch/pull GitHub
2. search repo
3. if still missing, write blocker report
4. continue next safe task

## Telegram reporting

If Hermes is available, sync cycles should send summarized status when:

- pull failed
- local dirty drift blocks pull
- queue prompt missing
- service/timer failed
- origin/main advanced and was pulled successfully
- critical policy changed

Do not send secrets, tokens, private env values, cookies, or raw traces.

## Success criteria

The sync system is healthy when:

- GitHub commits appear on `AUTOMATION_SERVER` automatically within the timer interval
- prompt files are discoverable without owner SSH/manual copy
- dirty state is reported and not destroyed
- queue ingestion sees new safe tasks
- Telegram/Hermes reports degraded states
- systemd timer survives logout/reboot
