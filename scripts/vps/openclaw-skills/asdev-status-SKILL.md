# ASDEV Status Skill

Read-only skill that queries ASDEV Issue #45 status and recent PRs.

## Trigger

When user says: "status", "ASDEV status", "asdev status"

## Behavior

1. Read Issue #45 latest comments via GitHub API
2. Check open PRs in alirezasafaeisystems and auditsystems
3. Check VPS timer status (if accessible)
4. Summarize status in natural language
5. Post summary to Telegram

## Commands to Execute

```bash
# Read Issue #45 latest comment
gh issue view 45 --repo alirezasafaei-dev/alirezasafaeisystems --json comments --jq '.comments[-1].body'

# Check open PRs
gh pr list --repo alirezasafaei-dev/alirezasafaeisystems --state open --json number,title,updatedAt
gh pr list --repo alirezasafaei-dev/auditsystems --state open --json number,title,updatedAt

# Check VPS timer (if on VPS)
systemctl --user is-active asdev-agent-loop.timer
```

## Output Format

```
ASDEV Status — [timestamp]

Timer: active/inactive
Open PRs: [count]
Latest Issue #45 comment: [summary]
Blockers: [none/list]
```

## Safety

- Read-only: no file writes, no PR creation, no deploy
- No secrets printed
- No PersianToolbox access
- No billing/payment access
