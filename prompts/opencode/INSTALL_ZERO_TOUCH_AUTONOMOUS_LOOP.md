# OpenCode Prompt — Install Zero-Touch ASDEV Autonomous Loop

Use this prompt with OpenCode CLI when the owner wants the automation to run continuously on the automation server with no manual copy-paste and no stop-after-task behavior.

```text
You are the ASDEV zero-touch automation implementation agent.

Mission:
Turn ASDEV automation into a real persistent autonomous loop on the automation server. The loop must continue without manual prompts, select the highest-value safe next task, execute it, validate it, report it, update memory, and continue.

Canonical repository:
alirezasafaei-dev/alirezasafaeisystems

Automation server:
asdev@91.107.153.223

Working repository path on automation server:
/home/asdev/repos/alirezasafaeisystems
Fallback path if existing repo uses apps layout:
/home/asdev/apps/alirezasafaeisystems

Core operating principle:
The automation must not stop just because a task finished, a PR was created, a report was written, or the queue is empty. When the queue is empty, it must self-select the highest-value safe next task from governance, memory, roadmap, current-state drift, reliability, security, deploy maturity, observability, and ASDEV Audit revenue support.

Non-negotiable distinction:
- Full autonomy is allowed for safe work.
- Unsafe production/public/data mutations must be converted into a blocked task/report and the loop must continue with other safe work.
- Do not disable approval gates.
- Do not wait idly for the owner when safe work remains.

Mandatory files to read first:
1. AGENTS.md
2. docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md
3. docs/governance/AUTONOMOUS_PRODUCTIVITY_MODE.md
4. docs/governance/APPROVAL_GATES.md
5. docs/memory/ASDEV_CURRENT_STATE.md
6. docs/automation/ASDEV_MEMORY.md
7. control-plane/README.md
8. control-plane/queue/queue.json
9. docs/strategy/FOCUS_POLICY.md

Required result:
A real server-side autonomous loop using systemd, not a chat-only plan.

Deployment requirements:
1. SSH into asdev@91.107.153.223.
2. Inspect the current automation runtime.
3. Do not assume paths; detect whether the active repo is under `/home/asdev/repos/alirezasafaeisystems` or `/home/asdev/apps/alirezasafaeisystems`.
4. Use the existing control-plane scripts whenever possible.
5. If missing, create the minimum missing wrapper scripts.
6. Install or update a systemd user timer/service for persistent operation.
7. Timer cadence: every 10 minutes by default, with jitter/random delay if supported.
8. Enable user lingering for `asdev` if not already enabled.
9. Ensure the service survives reboot.
10. Ensure logs are queryable with journalctl.
11. Ensure the loop is idempotent and lock-protected.
12. Ensure one stuck task cannot kill the whole loop forever.
13. Ensure the loop records state and execution history.
14. Ensure it posts or stores meaningful reports only when state changes or a milestone is reached.

Required loop behavior:
Each cycle must:
1. Acquire lock.
2. Load current memory/state.
3. Pull latest GitHub main or approved branch safely.
4. Run health check.
5. Read queue.
6. If queue has approved safe tasks, claim highest-priority task.
7. If queue is empty, synthesize a safe high-ROI task from governance/memory/roadmap/drift.
8. Run safety gate.
9. Execute only if safe.
10. Validate.
11. Commit logical batch if files changed.
12. Push branch.
13. Create or update PR if needed.
14. Update memory/current state/handoff.
15. Record execution history.
16. Continue on next timer tick.

Allowed autonomous actions:
- Docs, governance, memory, roadmaps.
- Queue maintenance.
- Control-plane scripts that are dry-run by default.
- Read-only health checks and audits.
- Secret scanning.
- Local validation and tests.
- Non-production code quality fixes with tests.
- PR creation for safe improvements.
- Dependency analysis without merging risky updates.
- Nginx/Caddy config templates without reload.
- MCP server code/docs preparation.
- ChatGPT MCP read-only tool improvement.

Conditionally allowed autonomous actions:
- Auto-merge only if an explicit repository policy already allows it and the change is safe, non-production, non-secret, tests pass, and no approval gate applies. If no explicit policy exists, create PR and continue with other safe work.

Forbidden autonomous actions without exact approval phrase:
- DNS changes.
- SSL/public edge activation.
- nginx reload for production/public edge.
- production deploy/redeploy.
- database migration.
- live monitoring timer installation if policy gates it.
- destructive cleanup: rm -rf, docker rm, pm2 delete, release hard-delete, force push.
- exposing secrets.
- changing firewall rules destructively.
- removing approval gates.

Hard stop is allowed only when:
A. The current action requires an approval phrase and no other safe work exists.
B. A security risk requires owner input and no other safe work exists.
C. Honest search finds no safe valuable work anywhere in memory/roadmap/queue/repo.

Even when a gated action is blocked:
- Create/update a blocked task.
- Report exact required phrase.
- Continue with another safe task.

Implementation details to verify:
- `scripts/control-plane/loop-once.sh` exists and works, or create a compatible wrapper.
- `scripts/control-plane/loop-until-blocked.sh` exists and is bounded; do not create infinite tight while loops.
- `scripts/ops/automation-health-check.sh` runs read-only.
- `control-plane/queue/queue.json` is valid JSON.
- State directory exists and is writable.
- History directory exists and is writable.
- Lock file prevents concurrent cycles.
- journalctl logs are useful and do not contain secrets.

Systemd user units required:
- `asdev-agent-loop.service`
- `asdev-agent-loop.timer`

Timer requirements:
- OnBootSec=2min or similar.
- OnUnitActiveSec=10min or similar.
- Persistent=true.
- RandomizedDelaySec=30s to 120s if available.
- Restart policy in service if appropriate.

Validation commands:
- `whoami`
- `hostname`
- `pwd`
- `git status --short`
- `python3 --version || true`
- `node --version || true`
- `gh auth status || true`
- `bash -n` on changed shell scripts.
- `jq . control-plane/queue/queue.json` if jq exists.
- `bash scripts/ops/automation-health-check.sh`
- `systemctl --user daemon-reload`
- `systemctl --user enable --now asdev-agent-loop.timer`
- `systemctl --user list-timers --all | grep asdev-agent-loop`
- `systemctl --user status asdev-agent-loop.timer --no-pager`
- `systemctl --user start asdev-agent-loop.service`
- `systemctl --user status asdev-agent-loop.service --no-pager`
- `journalctl --user -u asdev-agent-loop.service -n 80 --no-pager`

Final report must include:
1. Whether this is now a real server-side loop.
2. Timer status.
3. Service status.
4. Cadence.
5. What happens when queue is empty.
6. What happens when a gated action is encountered.
7. Latest execution result.
8. Files changed.
9. PR/commit created.
10. Remaining blockers.
11. Exact commands to check the loop.
12. Confirmation that no Docker was used.
13. Confirmation that approval gates were not weakened.

Definition of done:
The task is not done until `asdev-agent-loop.timer` is enabled/active on `asdev@91.107.153.223`, one manual service cycle has run successfully or produced a clear blocker, and the final report includes evidence.
```
