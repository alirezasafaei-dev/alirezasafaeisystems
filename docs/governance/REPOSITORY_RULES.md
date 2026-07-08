# Repository Rules — ASDEV

**Last Updated:** 2026-07-08

---

## Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `deploy/`, `scripts/deploy/` | platform | deploy engine |
| `scripts/ops/`, `scripts/monitoring/` | platform | ops probes |
| `control-plane/` | platform | AUTOMATION_HOST OS |
| `docs/automation/`, `docs/governance/` | platform | agent OS |
| `sites/live/<site>/` | product + platform registry | product source |
| `.github/workflows/` | platform | CI |

Default CODEOWNER: `@alirezasafaei-dev`

---

## Allowed without special phrase

- Documentation, architecture, governance  
- Scripts that are dry-run / read-only by default  
- Control plane queue/memory/health  
- Templates, project.yaml, standards  
- Tests, refactors with no production mutation  
- Security **audits** (no destructive fix of remote secrets)  

## Requires approval phrase

See [APPROVAL_GATES.md](./APPROVAL_GATES.md).

---

## Never commit

- `.env`, private keys, tokens  
- Raw production secrets  
- Large binaries / `node_modules` / `.next`  
- Customer PII dumps  

Use `ASDEV_PRIVATE/` on AUTOMATION_HOST only.

---

## Branching

- One meaningful PR per subsystem or mission batch  
- Prefer `ops/…` or `docs/…` prefixes  
- No force-push to `main`  
