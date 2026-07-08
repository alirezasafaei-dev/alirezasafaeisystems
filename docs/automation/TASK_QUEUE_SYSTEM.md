# ASDEV Task Queue System

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Storage:** local filesystem JSON (no external SaaS)

---

## Goals

- Durable autonomous work queue on AUTOMATION_HOST  
- Explicit IDs, status, owner, priority, dependencies  
- Audit log per transition  
- Safe selection (skip gated tasks without phrases)  

---

## Storage layout

```
control-plane/queue/
  queue.json           # active queue document
  archive/             # completed/cancelled snapshots
  schema.json          # schema version
```

Runtime writes may also go to gitignored `control-plane/state/queue-live.json` if desired.

---

## Task schema

```json
{
  "id": "ASDEV-YYYYMMDD-NNN",
  "title": "short title",
  "status": "pending|approved|in_progress|blocked|done|cancelled",
  "owner": "agent-id or human",
  "priority": 1,
  "depends_on": ["ASDEV-..."],
  "approval_required": null,
  "tags": ["docs", "iran-ro", "prod-gated"],
  "created_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "logs": ["timestamp message"],
  "result": null
}
```

### Status machine

```
pending → approved → in_progress → done
                 ↘ blocked
pending → cancelled
```

`approved` means either no gate or owner phrase present for that gate.

---

## Priority

| Priority | Meaning |
|----------|---------|
| 1 | Critical reliability / active incident |
| 2 | Control plane / production prep |
| 3 | Standard ops |
| 4 | Cleanup / nice-to-have |
| 5 | Frozen backlog candidate |

Lower number = higher priority.

---

## Selection algorithm

1. Load `queue.json`  
2. Filter `status in (pending, approved)`  
3. Drop tasks with unmet `depends_on`  
4. Drop tasks whose `approval_required` is set and phrase not in session context  
5. Sort by priority ASC, then `created_at` ASC  
6. Claim first → `in_progress`, append log  

Implementations:

- `scripts/control-plane/queue-list.sh`  
- `scripts/control-plane/queue-add.sh`  
- `scripts/control-plane/queue-claim.sh`  
- `scripts/control-plane/queue-complete.sh`  

---

## Relation to existing docs

| Legacy | Role |
|--------|------|
| `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` | Human-readable mission queue |
| `control-plane/queue/queue.json` | Machine queue |
| Issue #45 command bus | Optional GitHub-facing bus |

Both human markdown queue and JSON queue should stay roughly aligned after major work.

---

## Audit requirements

Every claim/complete/block must append:

```
[ISO-8601] agent=<id> event=claim|complete|block detail=...
```

No secrets in logs.

---

## Non-goals

- Distributed multi-host consensus  
- SaaS queue (Linear/Jira) as required dependency  
- Auto-running production tasks  
