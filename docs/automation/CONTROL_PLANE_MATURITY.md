# Control Plane Maturity — Ownership, Heartbeat, Retry, History

**Last Updated:** 2026-07-08

---

## Features

| Feature | Script |
|---------|--------|
| Agent heartbeat | `scripts/control-plane/agent-heartbeat.sh` |
| Stale task detection | `scripts/control-plane/detect-stale-tasks.sh` |
| Retry policy | `scripts/control-plane/retry-policy.sh` |
| Execution history | `scripts/control-plane/record-execution.sh` → `control-plane/history/executions.jsonl` |
| Bounded loop | `loop-once.sh`, `loop-until-blocked.sh` |
| Failure hints | `failure-recovery-hint.sh` |

## Policies

### Ownership

- Claim sets `owner` to `ASDEV_AGENT_ID`  
- Heartbeat proves agent still alive on AUTOMATION_HOST  

### Stale tasks

- `in_progress` older than 24h → report  
- `--reset-stale` returns them to `approved` (safe)  

### Retry

- On failure: `retry-policy.sh --id ID --fail "reason"`  
- After `ASDEV_MAX_RETRY` (default 3) → `blocked`  

### No uncontrolled loops

- Max iterations via `ASDEV_LOOP_MAX`  
- Never auto-runs gated production phrases  

## Daily

```bash
export ASDEV_AGENT_ID=automation-host-agent
bash scripts/control-plane/agent-heartbeat.sh
bash scripts/control-plane/detect-stale-tasks.sh
bash scripts/ops/automation-health-check.sh
```
