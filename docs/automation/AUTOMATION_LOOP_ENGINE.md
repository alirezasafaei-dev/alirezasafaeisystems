# Automation Loop Engine

**Version:** 1.0  
**Last Updated:** 2026-07-08

---

## Contract

Every loop iteration:

1. **Read state** — AGENT_MEMORY, queue, health  
2. **Select approved task** — `queue-claim.sh`  
3. **Execute** — only if safe / phrase satisfied  
4. **Validate** — health or deploy checks  
5. **Report** — docs/reports or control-plane logs  
6. **Update memory** — AGENT_MEMORY / handoff  
7. **Continue or stop** — bounded loops only  

No infinite uncontrolled execution.

---

## Implementations

| Entry | Behavior |
|-------|----------|
| `scripts/control-plane/loop-once.sh` | One iteration; health + claim |
| `scripts/agent-command-center/run-autonomous-loop.sh` | Existing multi-step loop |
| `scripts/agent-command-center/dry-run-loop.sh` | Dry-run |

---

## Audit log fields

Every action:

- timestamp (UTC ISO)  
- agent id  
- task id  
- action  
- result (ok/fail/blocked)  

Stored in `control-plane/logs/` (gitignored content) and/or task `logs[]` in queue.json.

---

## Stop conditions

| Condition | Action |
|-----------|--------|
| `approval_required` set, phrase absent | skip / blocked |
| Health `NOT_READY` | stop automation mutations |
| Security risk | stop and report |
| Queue empty | exit cleanly |

---

## Relation to production

Loop engine **never** implies production approval.  
Deploy scripts still require exact phrases.
