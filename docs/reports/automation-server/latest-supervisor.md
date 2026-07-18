# ASDEV Supervisor Report

| Item | Value |
|---|---|
| Started | 2026-07-18T06:00:58Z |
| Finished | 2026-07-18T06:01:02Z |
| Environment | asdevserve |
| Hostname | asdevserve |
| Verdict | GO_WITH_WARNINGS |
| Passed | 16 |
| Warnings | 3 |
| Failed | 0 |
| Auto-healed | 0 |
| Skipped (cooldown) | 0 |
| Skipped (not allowlisted) | 0 |

## Checks
- PASS [GIT-005] On branch: main
- PASS [GIT-006] Remote origin reachable
- PASS [GIT-008] No divergence (ahead=0 behind=0)
- PASS [GIT-009] Already up to date
- PASS [SVC-asdev-github-sync.timer] Timer active
- WARN [SVC-asdev-agent-loop.timer] Timer not found
- PASS [SVC-asdev-health-monitor.timer] Timer active
- PASS [SVC-asdev-mcp-monitor.timer] Timer active
- PASS [SVC-asdev-supervisor.timer] Timer active
- WARN [SVC-asdev-bot.service] Optional service not running (state=inactive) — expected when disabled
- PASS [SVC-asdev-github-sync.service] Oneshot service completed successfully (inactive, result=success)
- PASS [SVC-asdev-agent-loop.service] Oneshot service completed successfully (inactive, result=success)
- PASS [SVC-asdev-health-monitor.service] Oneshot service completed successfully (inactive, result=success)
- PASS [SVC-asdev-mcp-monitor.service] Service transitioning (state=activating)
- PASS [MCP-001] MCP endpoint healthy (HTTP 307, verdict=PASS)
- WARN [SYS-001] Disk usage high: 81%
- PASS [SYS-002] Memory usage: 43%
- PASS [SYS-003] Network reachable (github.com)
- PASS [PROV-001] OpenCode available

## Verdict
All critical checks passed (non-critical warnings). Loop may proceed with caution.
