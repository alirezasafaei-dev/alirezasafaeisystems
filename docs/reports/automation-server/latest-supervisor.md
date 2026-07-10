# ASDEV Supervisor Report

| Item | Value |
|---|---|
| Started | 2026-07-10T16:06:50Z |
| Finished | 2026-07-10T16:06:56Z |
| Environment | UNKNOWN |
| Hostname | asdev |
| Verdict | GO_WITH_WARNINGS |
| Passed | 9 |
| Warnings | 5 |
| Failed | 0 |
| Auto-healed | 0 |

## Checks
- PASS [GIT-005] On branch: main
- PASS [GIT-006] Remote origin reachable
- PASS [GIT-008] No divergence (ahead=0 behind=0)
- PASS [GIT-009] Already up to date
- WARN [SVC-asdev-github-sync] Timer not found
- PASS [SVC-asdev-agent-loop] Timer active
- WARN [SVC-asdev-health-monitor] Timer not found
- WARN [SVC-asdev-mcp-monitor] Timer not found
- WARN [SVC-asdev-bot] Service not running
- WARN [MCP-001] MCP endpoint returned HTTP 307
- PASS [SYS-001] Disk usage: 47%
- PASS [SYS-002] Memory usage: 18%
- PASS [SYS-003] Network reachable (github.com)
- PASS [PROV-001] OpenCode available

## Verdict
All critical checks passed (non-critical warnings). Loop may proceed with caution.
