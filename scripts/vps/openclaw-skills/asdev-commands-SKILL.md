# ASDEV Commands Skill

Read-only command submitter. Posts commands to Issue #45.

## Trigger

When user says: "run [task]", "stop", "safe-mode"

## Behavior

1. Parse command from user message
2. Post corresponding [ASDEV COMMAND] to Issue #45
3. Confirm command posted
4. VPS runner processes the command

## Commands

| User says | Posts to Issue #45 |
|---|---|
| "status" | [ASDEV STATUS] |
| "stop" | [ASDEV STOP] |
| "safe-mode" | [ASDEV SAFE-MODE] |
| "run [task]" | [ASDEV RUN [task]] |

## Safety

- Only posts comments to Issue #45
- No direct execution
- No file writes
- No deploy
- No PersianToolbox access
- No billing/payment access
