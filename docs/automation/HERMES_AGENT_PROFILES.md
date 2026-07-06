# Hermes Agent Profiles — ASDEV Registry

**Purpose:** Map CLI agents to Hermes profiles for kanban routing and isolated execution.  
**Controller:** `hermes-asdev-controller` — does not implement product code; classifies and dispatches.

References: [Hermes Profiles](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)

---

## Profile naming convention

```text
hermes-{role}-{agent}
```

Examples:

```text
hermes-asdev-controller      # orchestrator (no product commits by default)
hermes-code-codex            # focused implementation
hermes-review-grok           # critique and strategy pressure-test
hermes-docs-gemini           # long-context docs
hermes-code-deepseek         # low-cost code drafts
hermes-ops-mimo              # workspace hygiene, doc sync
hermes-autonomy-devin        # tight-spec autonomous runs (gated)
hermes-scope-antigravity     # larger scoped implementation (gated)
```

---

## Controller profile

| Field | Value |
|---|---|
| **Name** | `hermes-asdev-controller` |
| **Description** | ASDEV task classifier and dispatcher. Routes kanban tasks to specialist profiles by repo_scope, product_goal, and approval_required. Never edits persiantoolbox runtime without owner_approved_persiantoolbox=true. Posts reports to PR #42. |
| **Autonomy** | docs-only + orchestration |
| **Default repos** | `alirezasafaeisystems` (governance docs only) |
| **Tools** | `gh`, kanban CLI, `hermes send`, read-only git |
| **YOLO** | **disabled** |

### Routing rules (kanban decomposer input)

```text
IF repo_scope includes persiantoolbox AND NOT owner_approved_persiantoolbox
  → assign read-only profile OR block

IF task_type == implementation AND repo == auditsystems
  → hermes-code-codex (primary) OR hermes-code-deepseek (draft)

IF task_type == review OR critique
  → hermes-review-grok

IF task_type == docs OR architecture
  → hermes-docs-gemini

IF task_type == hygiene OR doc-sync
  → hermes-ops-mimo

IF task_type == autonomous AND owner_approved_autonomy
  → hermes-autonomy-devin OR hermes-scope-antigravity
```

---

## Worker profiles

### hermes-code-codex

| Field | Value |
|---|---|
| **Best for** | Focused `auditsystems` implementation, tests, bug fixes |
| **Avoid** | Broad refactors, PersianToolbox, billing activation |
| **Autonomy** | code-implementation (single repo) |
| **Ideal task size** | 1–3 files, clear acceptance criteria |
| **Validation** | `pnpm typecheck && pnpm lint && pnpm test && pnpm build` |
| **Risk** | Medium |

### hermes-review-grok

| Field | Value |
|---|---|
| **Best for** | Ruthless critique, product strategy, repo audits, decision pressure-testing |
| **Avoid** | Large autonomous diffs |
| **Autonomy** | read-only + report |
| **Ideal task size** | Review local commits or PR diff |
| **Validation** | N/A (read-only) |
| **Risk** | Low |

### hermes-docs-gemini

| Field | Value |
|---|---|
| **Best for** | Long-context docs, restructuring, summaries, large file review |
| **Avoid** | Production code without review |
| **Autonomy** | docs-only |
| **Ideal task size** | 1–5 markdown files |
| **Validation** | Link check, no secrets |
| **Risk** | Low |

### hermes-code-deepseek

| Field | Value |
|---|---|
| **Best for** | Low-cost implementation drafts, refactor planning |
| **Avoid** | Final production commit without Codex review |
| **Autonomy** | code-draft |
| **Ideal task size** | Spike / prototype |
| **Validation** | Same as Codex when promoted to implement |
| **Risk** | Medium |

### hermes-ops-mimo

| Field | Value |
|---|---|
| **Best for** | Workspace hygiene, repetitive doc sync, status updates |
| **Avoid** | Product logic, PersianToolbox |
| **Autonomy** | docs-only |
| **Ideal task size** | Index updates, changelog sync |
| **Validation** | lint docs |
| **Risk** | Low |

### hermes-autonomy-devin

| Field | Value |
|---|---|
| **Best for** | Tight-spec autonomous implementation with explicit owner gate |
| **Avoid** | Vague tasks, protected repos |
| **Autonomy** | requires owner gate |
| **Ideal task size** | Well-defined PR-sized scope |
| **Validation** | Full project validation + human review before push |
| **Risk** | **High** |

### hermes-scope-antigravity

| Field | Value |
|---|---|
| **Best for** | Larger scoped implementation with strict boundaries |
| **Avoid** | Multi-repo unfocused work |
| **Autonomy** | requires owner gate |
| **Ideal task size** | Feature slice with rollback plan |
| **Validation** | Full validation per repo |
| **Risk** | **High** |

---

## External CLI agents (non-Hermes)

When a task explicitly names Codex/Grok/Gemini CLI outside Hermes:

| Agent | Invocation pattern | Hermes role |
|---|---|---|
| Codex CLI | Separate session | Controller creates task; worker script invokes |
| Grok (Cursor) | IDE session | Review-only tasks |
| Gemini CLI | If installed | Docs tasks |

**Rule:** Even external CLIs report through PR #42 template; Hermes tracks kanban state.

---

## Profile setup checklist (Phase P1 — local)

```bash
# Example — do not run in production automation without owner OK
hermes profile create hermes-asdev-controller --description "ASDEV dispatcher..."
hermes profile create hermes-code-codex --description "AuditSystems implementation..."
# ... repeat for each profile
hermes kanban init
hermes kanban boards create asdev-audit
```

Store profile export archives in `docs/automation/profiles/` (future, no secrets).

---

## Cost / limit notes

| Profile | Cost note |
|---|---|
| Codex | Usage windows / subscription limits |
| Grok | API or IDE session |
| Gemini | Long context — watch token usage |
| DeepSeek | Low cost — good for drafts |
| Devin / Antigravity | Highest cost — gate strictly |
| Controller | Small model OK (classification only) |

---

## Report expectations (all profiles)

Every worker must end with [`REPORT_TEMPLATE`](../agent-command-center/REPORT_TEMPLATE.md) posted to PR #42, including:

- ASDEV Audit goals supported
- Validation results (pass/fail honest)
- What was not done
- Owner approval needed (if any)