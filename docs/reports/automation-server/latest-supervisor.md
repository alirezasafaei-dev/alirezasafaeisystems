# ASDEV Supervisor Report

| Item | Value |
|---|---|
| Started | 2026-07-12T16:13:07Z |
| Finished | 2026-07-12T16:13:18Z |
| Environment | UNKNOWN |
| Hostname | asdev |
| Verdict | NO_GO |
| Passed | 12 |
| Warnings | 5 |
| Failed | 2 |
| Auto-healed | 0 |
| Skipped (cooldown) | 0 |
| Skipped (not allowlisted) | 0 |

## Checks
- PASS [GIT-005] On branch: codex/self-hosted-ci-mother
- PASS [GIT-006] Remote origin reachable
- FAIL [GIT-007] Code-bearing divergence detected (ahead=27 behind=24) — NO_GO
- WARN [GIT-009] Fast-forward failed
- WARN [SVC-asdev-github-sync.timer] Timer not found
- PASS [SVC-asdev-agent-loop.timer] Timer active
- WARN [SVC-asdev-health-monitor.timer] Timer not found
- WARN [SVC-asdev-mcp-monitor.timer] Timer not found
- WARN [SVC-asdev-supervisor.timer] Timer not found
- FAIL [SVC-asdev-bot.service] Critical service not running (state=inactive)
- PASS [SVC-asdev-github-sync.service] Oneshot service completed successfully (inactive, result=success)
- PASS [SVC-asdev-agent-loop.service] Service transitioning (state=activating)
- PASS [SVC-asdev-health-monitor.service] Oneshot service completed successfully (inactive, result=success)
- PASS [SVC-asdev-mcp-monitor.service] Oneshot service completed successfully (inactive, result=success)
- PASS [MCP-001] MCP endpoint healthy (HTTP 307, verdict=WARN)
- PASS [SYS-001] Disk usage: 58%
- PASS [SYS-002] Memory usage: 14%
- PASS [SYS-003] Network reachable (github.com)
- PASS [PROV-001] OpenCode available

## Verdict
Critical failures detected. Loop must not proceed until resolved.
