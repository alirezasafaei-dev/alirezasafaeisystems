# PersianToolbox Protection — Automation Policy

**Status:** Critical guard — authoritative for all agents and Hermes profiles  
**PR reference:** `# Critical Guard — PersianToolbox Production Protection` (PR #42)

---

## Classification

PersianToolbox is **protected production software**, not a sandbox.

| Fact | Value |
|---|---|
| Live site | https://persiantoolbox.ir |
| Repository | `alirezasafaei-dev/persiantoolbox` |
| Scale | ~101 real tools |
| Tests | ~1300 passing (owner context) |
| Deploy | Clean production deploys |
| Investment | ~1 year owner work |

**Strategic role:** Traffic engine and soft lead source for ASDEV Audit — not a secondary product battlefield.

---

## Hard rules for automation

| Rule | Enforcement |
|---|---|
| No casual edits | Controller default: `persiantoolbox` = read-only |
| No exploratory refactors | Block kanban tasks without Tier 2 approval |
| No broad CTA experiments | Docs plan first; owner approves implementation |
| No route/template/analytics changes without approval | Tier 2 gate |
| No merging PT work into unrelated automation tasks | Separate branch + PR |
| No auto-push | Ever, without `Approved (special): persiantoolbox ...` |

> PersianToolbox production stability is more valuable than any quick ASDEV Audit CTA experiment.

---

## Allowed without extra approval

1. Read-only inspection (`git log`, read files, grep)
2. Documentation-only planning in `alirezasafaeisystems` docs
3. Strategy notes that **do not touch** `persiantoolbox` runtime
4. Copy/link proposals written as plans — **not implemented**

Hermes profiles allowed: `hermes-review-grok` (read-only), `hermes-docs-gemini` (mother-repo docs only)

---

## Requires explicit owner approval

Any change to PersianToolbox:

- Runtime code
- UI components
- Routing / templates
- Analytics / CTA logic
- Build configuration (`package.json`, CI)
- Tests (unless fixing regression from approved change)
- Deployment scripts
- Shared utilities used by tools

**Approval format:**

```text
Approved (special): persiantoolbox — {exact scope}
```

---

## If owner approves PersianToolbox code

| Requirement | Detail |
|---|---|
| Branch | Separate branch — never mixed with auditsystems automation |
| Commit | Single-purpose commit message |
| Validation | `pnpm typecheck && pnpm lint && (pnpm test:ci \|\| pnpm test) && pnpm build` |
| Report | Exact files, reason, ASDEV goal, validation output, rollback plan |
| Scope proof | Confirm no unrelated tools/flows touched |
| Hermes profile | Never `hermes-autonomy-devin` default — explicit only |

---

## Hermes / kanban defaults

Every ASDEV kanban task body must include:

```yaml
protected_repos:
  - persiantoolbox
owner_approved_persiantoolbox: false
```

Controller routing:

```text
IF target repo == persiantoolbox AND NOT owner_approved_persiantoolbox
  → block OR assign read-only review task only
```

---

## Local commits pending review (2026-07-06)

| Commit | Type | Automation stance |
|---|---|---|
| `c2fe53c2` trust + audit routing | production-sensitive | Hold — needs special approval |
| `68429de2` salary hub CTA | production-sensitive | Hold — recommend revert unless approved |
| `b1bc7ef9` tool template doc | docs-only | Safer — still separate push decision |

See PR #42 Protected Local Work Review.

---

## Audit routing without touching PersianToolbox

Preferred paths:

1. Route from `alirezasafaeisystems` qualification / case studies
2. Route from `auditsystems` CTAs directly
3. Document planned PT CTA in mother repo — implement only after approval

Do not weaken local-first promise for conversion experiments.

---

## Violation response

If a worker touches PersianToolbox without approval:

1. Stop execution immediately
2. Do not commit or push
3. Post incident note on PR #42
4. Task → `blocked` + owner review
5. Revert worktree if changes were made

---

## Related

- [`HERMES_APPROVAL_GATES.md`](HERMES_APPROVAL_GATES.md)
- [`../strategy/FOCUS_POLICY.md`](../strategy/FOCUS_POLICY.md)
- [`../agent-command-center/README.md`](../agent-command-center/README.md)