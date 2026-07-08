# Contribution Rules — ASDEV

**Last Updated:** 2026-07-08

---

## Before coding

1. Read `docs/automation/ASDEV_MEMORY.md` and `docs/automation/AGENT_MEMORY.md`  
2. Confirm focus: ASDEV reliability/ops or Audit product goals (`AGENTS.md`)  
3. Prefer extending existing deploy/monitoring/control-plane scripts  

## Quality bar

| Change type | Minimum validation |
|-------------|-------------------|
| Platform scripts | bash dry-run + secret scan |
| App (`src/` portfolio monorepo) | `pnpm lint`, `type-check`, `test` when touching app code |
| Docs only | review for secrets/IPs |
| Registry | `scripts/ops/validate-registry-schema.sh` |

## PR requirements

- Use PR template  
- Batch related work  
- Describe gates **not** taken  
- Link reports under `docs/reports/` when operational  

## After merge

- Update memory if decisions/state changed  
- Sync IRAN platform scripts when deploy engine changes  
- Do not stop autonomous productivity mode if safe work remains  
