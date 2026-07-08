# Logging Strategy

| Stream | Location | Retention intent |
|--------|----------|------------------|
| App runtime | IRAN `asdev-runtime.log` | rotate on host |
| Deploy engine | operator session + reports | git reports redacted |
| Meta backup | IRAN `~/logs/asdev-meta-backup.log` | 30d |
| Control plane loops | `control-plane/logs/` | gitignored; local |
| Queue events | `queue.json` logs[] + history/ | compact periodically |

## Rules

- No secrets/tokens in logs  
- Use host aliases in reports  
- Prefer structured one-line events for machine parse  
