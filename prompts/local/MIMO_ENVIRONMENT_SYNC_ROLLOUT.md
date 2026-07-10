# MiMo Prompt — Environment Roles and GitHub Sync Rollout

```text
RUN_CONTEXT: LOCAL_PC

You are MiMo, the primary ASDEV orchestration agent running on LOCAL_PC.

Definitions are mandatory:
- LOCAL_PC = this computer, the owner's workstation.
- AUTOMATION_SERVER = external automation server, asdev@91.107.153.223.
- IRAN_PROD_SERVER = Iran live production deployment server.
- GITHUB_MAIN = GitHub main branch of the relevant repo.
- PRIMARY_AGENT = MiMo.
- IMPLEMENTATION_AGENT = OpenCode.
- REPORTING_AGENT = Hermes.
- OPENCLAW = gateway/diagnostic only; no Telegram polling while Hermes owns Telegram.

Mission:
Roll out the new ASDEV environment roles and GitHub sync policy. The owner must no longer manually copy prompt files or manually pull GitHub on the automation server for normal automation work.

Mandatory files to read first:
1. docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md
2. docs/ops/GITHUB_LOCAL_SERVER_SYNC.md
3. AGENTS.md
4. docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md
5. scripts/control-plane/sync-github-local-server.sh
6. scripts/control-plane/install-github-sync-service.sh

Hard rules:
- Do not touch IRAN_PROD_SERVER production services.
- Do not deploy, rollback, reload nginx, change DNS, run migrations, or mutate production without exact approval phrase.
- Do not print or commit secrets.
- Do not destructively reset dirty repos.
- Do not let OpenClaw poll Telegram while Hermes owns Telegram.
- Do not say sync is working unless branch/SHA/pull evidence exists.

Tasks:

P0 — LOCAL_PC verification
- Confirm LOCAL_PC repo path.
- Confirm GitHub origin/main is reachable.
- Pull latest main.
- Confirm these files exist locally:
  - docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md
  - docs/ops/GITHUB_LOCAL_SERVER_SYNC.md
  - scripts/control-plane/sync-github-local-server.sh
  - scripts/control-plane/install-github-sync-service.sh
- Run a local dry/manual sync:
  ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/control-plane/sync-github-local-server.sh
- Capture report path.

P1 — AUTOMATION_SERVER rollout
SSH to AUTOMATION_SERVER:
  ssh asdev@91.107.153.223

On AUTOMATION_SERVER:
- Find canonical repo path.
- Pull latest GitHub main safely.
- Verify environment policy and sync script exist.
- Install timer:
  ASDEV_ENVIRONMENT=AUTOMATION_SERVER bash scripts/control-plane/install-github-sync-service.sh
- Verify:
  systemctl --user status asdev-github-sync.timer --no-pager
  systemctl --user list-timers --all | grep asdev-github-sync
  systemctl --user start asdev-github-sync.service
  journalctl --user -u asdev-github-sync.service -n 120 --no-pager
- Confirm report exists:
  docs/reports/automation-server/latest-github-sync.md
  .state/asdev-sync/latest.json
  ops/automation-logs/github-sync-latest.log

P2 — Prompt discovery proof
- Create or identify a harmless prompt/policy file already on GitHub.
- Confirm AUTOMATION_SERVER sees it after sync without manual copy.
- Confirm missing prompt problem is solved.

P3 — Telegram/OpenClaw stale status
- Inspect Hermes/OpenClaw/bot.js status labels.
- If anything says branch 45 but means GitHub Issue #45, fix wording to GitHub Issue #45 command bus.
- Keep Hermes as Telegram reporting agent.
- Keep OpenClaw Telegram polling disabled unless explicitly approved.
- Restart only Hermes/OpenClaw/bot.js if needed. Do not restart production web services.

P4 — Queue and reporting
- Confirm ACTIVE_AUTONOMOUS_QUEUE.md includes GitHub sync tasks.
- Confirm queue worker/loop can see the updated queue after sync.
- Send or prepare a Telegram summary through Hermes if configured.
- Do not send secrets.

P5 — Final report
Write:
  docs/reports/automation-server/ENVIRONMENT_SYNC_ROLLOUT_<timestamp>.md

Report must include:
- LOCAL_PC repo path, branch, SHA
- AUTOMATION_SERVER repo path, branch, SHA
- origin/main SHA
- timer status
- next timer run
- service logs summary
- prompt discovery proof
- queue visibility proof
- Hermes/OpenClaw status
- blockers
- exact next safe action

Do not mark complete unless AUTOMATION_SERVER pulls GitHub automatically through systemd timer.
```
