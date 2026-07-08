# Autonomous Productivity Mode

**Status:** ENABLED  
**Last Updated:** 2026-07-08

---

## Mode change

| From | To |
|------|-----|
| Finish assigned tasks and wait | Continuously improve ASDEV until a **real** approval gate |

---

## Core rule

If the next highest-value work does **not** require production mutation or destructive action, the agent **must not stop**.

After every completed unit of work:

1. Inspect system state  
2. Pick highest-value **safe** improvement  
3. Execute  
4. Batch commit  
5. Update memory  
6. Continue  

---

## Stop conditions ONLY

**A)** Production mutation needs exact phrase (see APPROVAL_GATES.md)  
**B)** Security risk detected  
**C)** No safe valuable work remains after honest search  

---

## Anti-patterns (forbidden)

- Stopping because “docs done” or “PR merged”  
- Stopping to wait for owner when only preparation remains  
- Creating micro-PRs for one mission  
- Inventing new gates for docs/refactor/tools  

---

## Priority heuristic

1. Reliability of CRITICAL_SITE app-layer + platform  
2. Control plane / agent OS maturity  
3. Deploy engine maturity  
4. Observability foundation  
5. Project standardization for multi-site  
6. Security audits  
7. Nice-to-have cleanup  

---

## Output every cycle

```
COMPLETED:
NEXT_SAFE_ACTION:
BLOCKED_ACTIONS:
SYSTEM_HEALTH:
```
