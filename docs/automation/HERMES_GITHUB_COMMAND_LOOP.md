# Hermes ↔ GitHub Command Loop

**Command thread:** [PR #42](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/42)  
**Poller:** `scripts/agent-command-center/monitor-pr.sh` (existing)  
**Future:** Hermes cron wraps monitor → kanban task creation

---

## Principle

GitHub owns **history and approval**. Hermes owns **execution and routing**. Neither replaces the other.

---

## Prompt detection

### Actionable prompt headings

| Pattern | Example |
|---|---|
| `# Next Agent Prompt — {title}` | Phase work packages |
| `Protected review requested.` | Report-only audits |
| `Hermes-first check requested.` | Architecture reviews |
| `# Decision — {title}` | Owner direction changes |
| Owner `Approved: {scope}` | Push/implementation approval |

### Report heading (required)

```md
# Agent Execution Report — {title}
```

### Guards (obey, do not execute as tasks)

- `# Critical Guard — {title}`
- `# Monitoring Continues`

Monitor implementation: `scripts/agent-command-center/monitor-pr.sh`

---

## Loop diagram

```text
┌──────────────┐     cron / manual      ┌─────────────────┐
│  PR #42      │ ◄──────────────────────│ monitor-pr.sh   │
│  comments    │                          └────────┬────────┘
└──────┬───────┘                                   │
       │ PROMPT_PENDING                            │
       ▼                                           ▼
┌──────────────┐     create task          ┌─────────────────┐
│ Owner prompt │ ────────────────────────►│ Hermes kanban   │
└──────────────┘                          │ board: asdev    │
                                          └────────┬────────┘
                                                   │ dispatch
                                                   ▼
                                          ┌─────────────────┐
                                          │ Worker profile  │
                                          │ + git worktree  │
                                          └────────┬────────┘
                                                   │
                                                   ▼
                                          ┌─────────────────┐
                                          │ gh pr comment   │
                                          │ (report)        │
                                          └────────┬────────┘
                                                   │
                                                   ▼
                                          ┌─────────────────┐
                                          │ Owner / ChatGPT │
                                          │ next prompt     │
                                          └─────────────────┘
```

---

## State tracking

### GitHub side

| Artifact | Location |
|---|---|
| Prompts | PR #42 issue comments |
| Reports | PR #42 issue comments |
| Approvals | PR comments: `Approved: ...` |
| Code truth | Branches + commits (after approved push) |

### Hermes side

| Artifact | Location |
|---|---|
| Monitor state | `docs/agent-command-center/STATE.json` |
| Kanban tasks | `~/.hermes/kanban/` (board `asdev-audit`) |
| Sessions | `~/.hermes/sessions/` |
| Cron jobs | `~/.hermes/cron/jobs.json` |

### Kanban task body template

```yaml
github_prompt_comment_id: "4896439275"
title: "E1-02 CTA hardening"
product_goal: "better conversion tracking"
repo_scope: ["auditsystems"]
protected_repos: ["persiantoolbox"]
agent_candidates: ["hermes-code-codex"]
selected_agent: "hermes-code-codex"
autonomy_level: "code-implementation"
approval_required: true
owner_approved: false
validation_commands:
  - "cd sites/live/auditsystems && pnpm typecheck && pnpm lint && pnpm test && pnpm build"
report_target: "pr:42"
out_of_scope: ["billing", "deploy", "persiantoolbox runtime"]
```

---

## Cron integration (Phase P2 — design only)

```bash
# Hourly: check PR #42 for pending prompts
# Pseudocode — not deployed
hermes cron create "0 * * * *" \
  "Run ASDEV PR monitor. If PROMPT_PENDING, create kanban task from latest prompt. Notify owner via Telegram." \
  --name "asdev-pr42-watch" \
  --script /path/to/sites/live/alirezasafaeisystems/scripts/agent-command-center/monitor-pr.sh \
  --deliver telegram
```

Existing GitHub Action: `.github/workflows/agent-command-center-hourly.yml` — warns only; does not run agents.

---

## GitHub webhook alternative (optional)

```bash
# Pseudocode — requires GitHub App or repo webhook → Hermes
hermes webhook subscribe asdev-github \
  --events "issue_comment" \
  --prompt "New comment on PR 42: {comment.body}. If actionable prompt, create kanban task." \
  --deliver log
```

**Note:** GitHub API key not configured in local Hermes status (2026-07-06). Until configured, use `gh` CLI in worker scripts.

---

## Report posting

Workers use `gh` (no secrets in docs):

```bash
gh pr comment 42 --repo alirezasafaei-dev/alirezasafaeisystems --body-file /tmp/report.md
```

Rules:

- Factual validation results
- No private tokens or env values
- Stop after posting — no next prompt without owner

---

## Failure modes

| Symptom | Fix |
|---|---|
| Monitor misses prompt | Add pattern to `PROMPT_PATTERNS` in monitor-pr.sh |
| Double execution | Check `STATE.json` + kanban claim atomicity |
| Report without prompt | Reject; post clarification comment |
| Worker edits wrong repo | Enforce `repo_scope` in task body; worktree per repo |

---

## Related

- [`HERMES_FIRST_ORCHESTRATION.md`](HERMES_FIRST_ORCHESTRATION.md)
- [`HERMES_APPROVAL_GATES.md`](HERMES_APPROVAL_GATES.md)
- [`../agent-command-center/REPORT_TEMPLATE.md`](../agent-command-center/REPORT_TEMPLATE.md)