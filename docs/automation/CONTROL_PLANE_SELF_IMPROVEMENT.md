# Control Plane Self-Improvement Notes

**Date:** 2026-07-08

## Findings this loop

| Finding | Action |
|---------|--------|
| Many overlapping Hermes/phase docs | Keep; index via AGENT_REGISTRY + architecture doc |
| agent-command-center vs control-plane scripts | control-plane = queue/health; ACC = dispatch legacy |
| OWNER_PC colocation | Accept; document load risk |
| Manual queue in markdown only | Added JSON queue + CLI |
| No unified health for gateways+queue | `automation-health-check.sh` |
| Unsafe patterns | Deploy still phrase-gated; no secret commits |

## Next continuous improvements

1. Deduplicate dispatch scripts behind one façade  
2. Optional user-systemd units for hermes/openclaw (owner approval)  
3. Queue archive job for `done` tasks  
4. Align ACTIVE_AUTONOMOUS_QUEUE.md generator from queue.json  
