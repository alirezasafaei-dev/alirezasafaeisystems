# ASDEV High-Autonomy Automation Pack — Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:execute to implement this plan task-by-task.

**Goal:** Move ASDEV from manual prompt-by-prompt execution to a production-grade multi-agent automation loop.

**Architecture:** Build on Phase P1 (profiles + kanban) and Phase P2 (scripts + dry-run) to create a durable, self-sustaining command loop with provider health checks, cron polling, approval gates, OpenCode integration, and a heavy job queue.

**Tech Stack:** Bash scripts, Hermes CLI, gh CLI, OpenCode CLI, JSON state files, markdown docs

---

## Current State Summary

| Component | Status |
|---|---|
| Phase P1 | ✅ Pushed to main (commit 8d0fb54) |
| Phase P2 | ⚠️ Local only (commit 0058769, branch `automation/hermes-github-command-loop-p2`) |
| P2 pushed | ❌ Branch not on remote |
| P2 PR | ❌ No PR exists |
| Hermes | ✅ v0.17.0, kanban board, 5 profiles |
| OpenCode | ✅ v1.17.13 installed |
| PR #42 | ✅ Merged |
| Open PRs | None |

---

## JOB 0 — Safety Snapshot

- [ ] Commit STATE.json fix to P2 branch
- [ ] Create `docs/automation/AUTOMATION_STATUS_SNAPSHOT.md`
- [ ] Verify all repos clean after commit

## JOB 1 — Finish Phase P2 Publication

- [ ] Push branch `automation/hermes-github-command-loop-p2`
- [ ] Open PR targeting main
- [ ] Verify only automation/docs/scripts changed
- [ ] Auto-merge if safe (docs/automation only)

## JOB 2 — Hermes Provider Health Check

- [ ] Test each configured provider without exposing secrets
- [ ] Create `docs/automation/HERMES_PROVIDER_HEALTH.md`
- [ ] Report health per provider

## JOB 3 — Durable GitHub Command Loop

- [ ] Create `scripts/agent-command-center/sync-github-to-kanban.sh`
- [ ] Create `scripts/agent-command-center/dispatch-next-task.sh`
- [ ] Create `scripts/agent-command-center/collect-agent-report.sh`
- [ ] Create `scripts/agent-command-center/update-command-state.sh`
- [ ] Add --dry-run mode to all scripts
- [ ] Create `docs/automation/GITHUB_COMMAND_LOOP_DURABILITY.md`

## JOB 4 — Hermes Cron Polling

- [ ] Create `docs/automation/HERMES_CRON_COMMAND_LOOP.md`
- [ ] Create `ops/hermes/cron.example.json`
- [ ] Document cron setup without deploying

## JOB 5 — Telegram/Email Approval Gate Design

- [ ] Inspect Hermes gateway config safely
- [ ] Create `docs/automation/HERMES_APPROVAL_GATEWAY.md`
- [ ] Define approval phrases and deny rules

## JOB 6 — OpenCode Worker Integration

- [ ] Test OpenCode read-only inspection
- [ ] Create `docs/automation/OPENCODE_WORKER.md`
- [ ] Create `ops/opencode/README.md`
- [ ] Create `ops/opencode/config.example.json`

## JOB 7 — Multi-Agent Heavy Queue

- [ ] Create `docs/automation/ASDEV_HEAVY_JOB_QUEUE.md`
- [ ] Include 12+ jobs with full YAML specs

## JOB 8 — Run One Safe Heavy Job

- [ ] Pick "Automation command loop reliability hardening"
- [ ] Execute in worktree
- [ ] Validate and commit

## JOB 9 — Self-Review

- [ ] Review all changes
- [ ] Fix any issues
- [ ] Verify no PersianToolbox changes

## JOB 10 — Final Publication

- [ ] Push all branches
- [ ] Open PRs
- [ ] Auto-merge safe PRs
- [ ] Post final report to GitHub

---

*Plan created. Executing inline with compose:execute.*
