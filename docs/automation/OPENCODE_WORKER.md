# OpenCode Worker — ASDEV Integration

**Status:** Available (2026-07-06)
**Version:** v1.17.13
**Model:** deepseek-v4-flash-free (default)

---

## Role

```yaml
role: code-worker
best_for:
  - implementation drafts
  - alternate review
  - codebase explanation
  - read-only inspection
avoid:
  - protected repos (persiantoolbox)
  - production deploy
  - direct main commits
  - billing/payment
permissions:
  persiantoolbox: read-only
  auditsystems: draft-implementation
  alirezasafaeisystems: full
  deploy: denied
  billing: denied
```

---

## Usage

### Read-only inspection

```bash
opencode run "Read {file} and produce a summary. Do not edit any files."
```

### Code draft

```bash
opencode run "Create a draft implementation of {feature} in {path}. Use existing patterns."
```

### Review

```bash
opencode run "Review the changes in {file} and suggest improvements. Read-only."
```

---

## Capabilities

| Capability | Status |
|---|---|
| Read files | ✅ |
| Write files | ✅ (controlled) |
| Run commands | ✅ (controlled) |
| Git operations | ✅ (controlled) |
| Model | deepseek-v4-flash-free |

---

## Safety Rules

1. **PersianToolbox:** Read-only. Never edit.
2. **Deploy:** Never run deploy commands.
3. **Billing:** Never modify payment/billing code.
4. **Main branch:** Never push directly to main.
5. **Secrets:** Never print or commit secrets.

---

## Integration with Hermes

OpenCode can be used as a worker profile:

```yaml
profile: hermes-opencode-worker
model: deepseek-v4-flash-free
role: code-draft
```

---

## Dry-Run Test

```bash
opencode run "Read docs/automation/README.md and produce a 3-line summary. Do not edit any files."
```

---

## Files

| File | Purpose |
|---|---|
| `docs/automation/OPENCODE_WORKER.md` | This file |
| `ops/opencode/README.md` | Setup guide |
| `ops/opencode/config.example.json` | Config template |

---

*OpenCode integration documented. Available as worker.*
