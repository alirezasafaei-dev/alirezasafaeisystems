# MiMo Agent Profiles — ASDEV Registry

**Purpose:** Map MiMo session roles to Hermes profiles for consistent handoffs.
**Created:** 2026-07-06 (Phase P1)

---

## Profile Summary

| MiMo Profile | Hermes Profile | Role | Autonomy |
|---|---|---|---|
| `asdev-controller` | `hermes-asdev-controller` | Classifier, dispatcher | Docs-only |
| `asdev-reviewer` | `hermes-asdev-reviewer` | Code review, critique | Read-only |
| `asdev-docs` | `hermes-asdev-docs` | Documentation, restructuring | Docs-only |
| `asdev-ops` | `hermes-asdev-ops` | Workspace hygiene, status | Local commands |
| `asdev-code-draft` | `hermes-asdev-code-draft` | Implementation drafts | Draft, no push |

---

## Profile Details

### asdev-controller

**File:** `.mimocode/agents/asdev-controller.md`
**Best for:** Task classification, routing, gate enforcement
**Avoid:** Product code, PersianToolbox, production deploy
**Risk:** Low

### asdev-reviewer

**File:** `.mimocode/agents/asdev-reviewer.md`
**Best for:** Ruthless critique, strategy pressure-testing, repo audits
**Avoid:** Large autonomous diffs, product changes
**Risk:** Low

### asdev-docs

**File:** `.mimocode/agents/asdev-docs.md`
**Best for:** Long-context docs, governance, restructuring
**Avoid:** Production code without review
**Risk:** Low

### asdev-ops

**File:** `.mimocode/agents/asdev-ops.md`
**Best for:** Workspace hygiene, doc sync, validation runs
**Avoid:** Product logic, PersianToolbox
**Risk:** Low

### asdev-code-draft

**File:** `.mimocode/agents/asdev-code-draft.md`
**Best for:** auditsystems implementation drafts, tests, bug fixes
**Avoid:** Broad refactors, PersianToolbox, billing, direct main commits
**Risk:** Medium

---

## Routing Rules

```
IF task_type == classification OR dispatch
  → asdev-controller

IF task_type == review OR critique
  → asdev-reviewer

IF task_type == docs OR architecture
  → asdev-docs

IF task_type == hygiene OR validation OR status
  → asdev-ops

IF task_type == implementation AND repo == auditsystems
  → asdev-code-draft

IF repo == persiantoolbox AND NOT owner_approved
  → BLOCK
```

---

## PersianToolbox Protection

All profiles deny PersianToolbox edits unless:

```
Approved (special): persiantoolbox — {exact scope}
```

Default for every task:

```yaml
protected_repos:
  - persiantoolbox
owner_approved_persiantoolbox: false
```

---

## Validation Commands

| Repo | Commands |
|---|---|
| auditsystems | `pnpm typecheck && pnpm lint && pnpm test && pnpm build` |
| alirezasafaeisystems | `pnpm type-check && pnpm lint && pnpm test && pnpm build` |
| persiantoolbox | Read-only (no edits without special approval) |
