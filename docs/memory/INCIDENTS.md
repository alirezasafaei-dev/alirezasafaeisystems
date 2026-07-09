# ASDEV Incidents Log

Append-only. Newest first. No secrets / raw IPs required.

---

## 2026-07-09 — Public blue-green post-cutover 502 (transient)

| Field | Value |
|-------|--------|
| Severity | SEV2 (public intermittent) |
| Host | public VPS (ubuntu · nginx · PM2 green) |
| Symptom | `/api/ready` 502 / timeouts after cutover |
| Cause | Node process stuck on **debugger/inspector** (`Debugger listening`); nginx upstream 3003 |
| Mitigation | Restart `persiantoolbox-green` without `NODE_OPTIONS` inspect; verify local 3003=200 |
| Status | Mitigated; monitor restart loops |
| Follow-up | Scrub inspect from env/pm2 start path; ensure deploy script never enables inspector |

---

## Template

```
## YYYY-MM-DD — title
Severity:
Symptom:
Cause:
Mitigation:
Status:
Follow-up:
```
