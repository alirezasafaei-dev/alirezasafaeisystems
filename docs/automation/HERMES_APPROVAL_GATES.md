# Hermes Approval Gates — ASDEV

**Purpose:** Map ASDEV owner approval rules to Hermes execution modes.  
**Rule:** Automation accelerates work; it never removes judgment.

References: [Hermes Security](https://hermes-agent.nousresearch.com/docs/user-guide/security)

---

## Hermes built-in controls

| Mechanism | ASDEV setting |
|---|---|
| Command approval mode | **manual** or **smart** — never **off** for workers |
| YOLO (`--yolo`) | **Forbidden** on all ASDEV profiles |
| Gateway `/approve` `/deny` | Enabled for owner Telegram |
| Hook allowlist | Required for shell hooks |
| API server approval endpoint | Use for optional n8n UI — not auto-approve |
| Timeout | Enforce per-task max runtime |

> Hermes warns: YOLO bypasses approvals. ASDEV workers must not use it.

---

## Gate tiers

### Tier 0 — No owner approval needed

| Action | Examples |
|---|---|
| Read-only inspection | `git status`, `git diff`, read files |
| Docs-only planning | Architecture notes, task proposals |
| Report normalization | Formatting agent output for PR |
| Monitor poll | `monitor-pr.sh` read GitHub |

Hermes autonomy: `read-only`, `docs-only`

---

### Tier 1 — Standard approval (PR comment)

| Action | Examples |
|---|---|
| Code changes in `auditsystems` | Features, fixes, tests |
| Code changes in `alirezasafaeisystems` | Governance UI, docs with app code |
| Local commits | Any repo |
| New Hermes profiles / cron jobs | Automation config |

**Approval format:**

```text
Approved: {scope description}
```

Examples:

- `Approved: push auditsystems commits ca435c7 9dd9bd6`
- `Approved: Hermes Phase P1 profile setup local only`

Hermes: block kanban `dispatch` until `owner_approved: true` on task.

---

### Tier 2 — Special owner approval

| Action | Why special |
|---|---|
| **PersianToolbox runtime/UI/routing/template/analytics/build/test** | Protected production — 101 tools, ~1300 tests |
| Push to `main` any repo | Release authority |
| Production deploy | Live user impact |
| Database migration (production) | Irreversible risk |
| Payment / billing activation | Revenue + legal |
| Server config / VPS | Ops surface |
| Force push, repo deletion | Destructive |
| `hermes-autonomy-devin` / Antigravity tasks | High autonomy |
| Package.json / build config (PersianToolbox) | Supply chain + CI |

**Approval format:**

```text
Approved (special): {explicit scope}
```

Must include rollback plan in task body for implementation tiers.

---

## PersianToolbox gate (summary)

Full policy: [`PERSIANTOOLBOX_PROTECTION.md`](PERSIANTOOLBOX_PROTECTION.md)

Controller rule:

```text
IF repo == persiantoolbox AND change_type != docs-only
  REQUIRE owner_approved_persiantoolbox == true
  ELSE status = blocked
```

Default kanban tasks: `protected_repos: [persiantoolbox]`

---

## Mapping to task statuses

| Status | Meaning | Gate |
|---|---|---|
| `proposed` | Prompt on PR #42 | — |
| `approved` | Owner approved scope | Tier 1/2 |
| `assigned` | Profile selected | After approved |
| `running` | Worker active | Hermes command approval on |
| `blocked` | Validation fail / missing approval | Owner action |
| `reported` | PR comment posted | — |
| `needs_review` | Awaiting owner summary | — |
| `approved_to_push` | Push explicitly OK | Tier 1/2 |
| `rejected` | Do not proceed | — |
| `frozen` | Out of ASDEV focus | — |
| `done` | Closed loop | — |

---

## n8n interaction (if added later)

n8n may:

- Send approval request notifications
- Display pending tasks
- Call Hermes API **status** endpoints

n8n may **not**:

- Auto-set `owner_approved: true`
- Trigger push/deploy nodes without owner click
- Invoke workers on PersianToolbox without Tier 2 flag

---

## Audit product focus gate

Before dispatch, controller checks task against [`FOCUS_POLICY.md`](../strategy/FOCUS_POLICY.md):

> Which ASDEV Audit goal does this task support?

If none → `frozen`; no worker spawn.

---

## Escalation

| Condition | Action |
|---|---|
| Agent requests YOLO | Deny; post guard reminder on PR |
| Validation fails twice | `blocked`; owner decides |
| WIP collision detected | Stop; protected review |
| Secret near exposure | Abort; redact report |