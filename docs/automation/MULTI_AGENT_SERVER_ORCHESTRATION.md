# ASDEV Multi-Agent Orchestration Config
# MiMo = Brain/Orchestrator on AUTOMATION_HOST

## Agent Registry

| Agent | Role | Location | Capabilities |
|-------|------|----------|--------------|
| **mimo** | Brain / Orchestrator | AUTOMATION_HOST | Planning, coordination, code review, architecture decisions |
| **claude** | Code Worker | AUTOMATION_HOST | Code generation, refactoring, debugging, testing |
| **mimo-local** | Interactive Dev | OWNER_PC | Local development, quick iterations |
| **opencode-local** | Code Worker | OWNER_PC | Fast code edits, refactoring |
| **codex-local** | Code Worker | OWNER_PC | Code generation, documentation |

## Orchestration Model

```
AUTOMATION_HOST (Server)
├── mimo (Brain)
│   ├── Reads queue from control-plane
│   ├── Plans task decomposition
│   ├── Assigns subtasks to workers
│   ├── Reviews output quality
│   └── Coordinates commits/PRs
├── claude (Worker)
│   ├── Executes code tasks
│   ├── Runs tests
│   └── Reports back to mimo
└── Control Plane
    ├── queue.json (task queue)
    ├── agents/ (agent profiles)
    ├── state/ (heartbeats, status)
    └── logs/ (execution history)

OWNER_PC (Local)
├── mimo-local (Interactive)
├── opencode-local (Worker)
└── codex-local (Worker)
```

## Task Flow

1. MiMo reads from queue or roadmap
2. MiMo decomposes task into subtasks
3. MiMo assigns subtasks to claude worker
4. Claude executes and reports
5. MiMo reviews quality
6. MiMo commits/creates PR
7. MiMo updates queue and memory

## MiMo Config for AUTOMATION_HOST

```yaml
# ~/.mimo/config.yaml (create on server)
role: orchestrator
mode: autonomous
workspace: /home/asdev/repos/alirezasafaeisystems
control_plane: /home/asdev/asdev-platform/control-plane
allowed_modes:
  - read-only
  - docs-only
  - automation-script
  - code-review
blocked_modes:
  - production-deploy
  - destructive
max_jobs: 2
report_to: control-plane
```
