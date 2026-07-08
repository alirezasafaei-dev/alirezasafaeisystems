# Branching Strategy — ASDEV

**Last Updated:** 2026-07-08  
**SoT:** GitHub `main`

---

## Default

| Branch | Purpose |
|--------|---------|
| `main` | Source of truth; production-ready platform docs/engine |
| `ops/<topic>` | Platform / control plane / deploy / ops |
| `docs/<topic>` | Docs-only when isolated |
| `feat/<topic>` | Product features (focus-policy constrained) |
| `fix/<topic>` | Bugfixes |

---

## Rules

1. **Never force-push `main`.**  
2. Prefer **one branch per subsystem batch** (no micro-branches for one file).  
3. Rebase/ff only when history is local or agreed.  
4. After merge: delete remote topic branch optional; local cleanup free.  
5. CRITICAL_SITE product code may live in `sites/live/*` (often gitignored on host) or separate product repos — platform registry still owns ports/deploy.

---

## Agent branching

- Agents open **one PR per major mission** when possible.  
- Stack only if merge order required; prefer sequential merges to `main`.  
