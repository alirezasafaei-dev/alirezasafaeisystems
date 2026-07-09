# ASDEV Memory Architecture

Permanent, structured memory for agents and humans.

| File | Role | Alias |
|------|------|-------|
| [ASDEV_CURRENT_STATE.md](./ASDEV_CURRENT_STATE.md) | Live snapshot | CURRENT_STATE |
| [ARCHITECTURE_MEMORY.md](./ARCHITECTURE_MEMORY.md) | Stable architecture map | — |
| [DECISION_LOG.md](./DECISION_LOG.md) | Dated decisions + rationale | DECISIONS |
| [ACTIVE_ROADMAP.md](./ACTIVE_ROADMAP.md) | Near-term roadmap | ROADMAP |
| [INCIDENTS.md](./INCIDENTS.md) | Outages / SEV log | — |
| [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) | Cross-session handoff | — |

**Loop policy:** `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`

Also:

- `docs/automation/ASDEV_MEMORY.md` — permanent summary  
- `docs/automation/AGENT_MEMORY.md` — session/agent working memory  
- `control-plane/queue/queue.json` — machine task state  

**Rule:** Every important operation updates at least CURRENT_STATE or DECISION_LOG.
