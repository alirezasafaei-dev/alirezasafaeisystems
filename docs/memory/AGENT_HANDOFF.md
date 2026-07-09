# Agent Handoff — ASDEV

**Update at end of meaningful sessions.**  
**Full protocol:** `docs/automation/AGENT_HANDOFF_PROTOCOL.md`

---

## Latest handoff — 2026-07-09

### What changed
- Installed official Autonomous Loop policy in GitHub SoT  
- Public VPS blue-green deployed product `37ba347` (green:3003) earlier session  
- Product main advanced (quality, SEO factory, blog Medium docs)  

### Where
- `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`  
- `docs/memory/*`  
- product: `persiantoolbox` main  

### Why
- Chat instructions must not be the only loop governance  
- Continuous improvement without task-by-task stop  

### Validation
- `automation-health-check.sh` → DEGRADED_NON_BLOCKING  
- Policy secret scan before commit  

### Risks
- Public host ≠ ASDEV IRAN app-layer host — do not confuse deploys  
- NODE_OPTIONS inspect can hang Next standalone  

### Next command
```bash
cd /home/dev13/ASDEV
git pull --ff-only origin main
# read policy first
# then: bash scripts/control-plane/queue-list.sh
# highest ROI safe work from missions A–E
```

### Owner approval
- Public edge / DNS / SSL / migrations still gated by phrases in APPROVAL_GATES.md  
