# ASDEV Audit — Agent Execution Board

**Last updated:** 2026-07-07
**Product:** ASDEV Audit Platform
**Purpose:** Task distribution, agent assignments, and escalation paths

---

## 1. Agent Profiles

### MiMo (Orchestration)

- **Role:** Primary orchestrator, planning, documentation, cross-project coordination
- **Strengths:** Architecture decisions, complex multi-file changes, roadmap management, documentation
- **Limits:** Does not do quick patches — delegates to OpenCode
- **When to use:**
  - Task requires understanding 3+ files and their relationships
  - Documentation or roadmap updates
  - Cross-project coordination (auditsystems ↔ brand site ↔ toolbox)
  - Complex refactoring that changes APIs
  - New feature planning and implementation
- **Working directory:** `/home/dev13/my-project`
- **Quality gate:** Must run `pnpm check` before marking task done

### OpenCode (Small Patches)

- **Role:** Fast implementation of well-defined, isolated changes
- **Strengths:** Quick bug fixes, UI tweaks, test additions, single-file features
- **Limits:** Does not do architecture changes, security-sensitive work, or database migrations
- **When to use:**
  - Single-file bug fix
  - Adding a test case
  - UI component tweaks
  - Simple API endpoint additions
  - Documentation updates within existing files
- **Working directory:** `/home/dev13/my-project/sites/live/auditsystems`
- **Quality gate:** Must run `pnpm lint` and `pnpm typecheck` before marking task done

### Codex (Critical Review)

- **Role:** Security review, architecture validation, critical path verification
- **Strengths:** Security analysis, code review, threat modeling, performance analysis
- **Limits:** Does not implement — only reviews and flags issues
- **When to use:**
  - Security-sensitive implementations (auth, payments, SSRF)
  - Database schema changes
  - Performance-critical changes
  - Pre-deployment review of critical paths
  - CSP/header configuration changes
- **Working directory:** `/home/dev13/my-project/sites/live/auditsystems`
- **Quality gate:** Must produce written review with findings and recommendations

### Grok (Risk Scout)

- **Role:** Risk assessment, edge case discovery, failure mode analysis
- **Strengths:** Finding edge cases, analyzing failure modes, risk quantification
- **Limits:** Does not implement — only reports risks
- **When to use:**
  - New feature risk assessment
  - Payment flow failure analysis
  - Queue job failure scenarios
  - Deployment rollback planning
  - Concurrency and race condition analysis
- **Working directory:** `/home/dev13/my-project/sites/live/auditsystems`
- **Quality gate:** Must produce risk report with severity and mitigation recommendations

### Hermes (Deploy/Status)

- **Role:** Deployment, operations, monitoring, infrastructure tasks
- **Strengths:** Shell scripts, PM2 management, cron jobs, health checks, VPS operations
- **Limits:** Does not write application code — only ops scripts and deployment
- **When to use:**
  - Deployment script creation or modification
  - Cron job setup and management
  - Health check implementation
  - Smoke test creation
  - VPS operations and monitoring
  - Backup and restore procedures
- **Working directory:** `/home/dev13/my-project/sites/live/auditsystems/scripts`
- **Quality gate:** Must run the script and verify it works before marking done

---

## 2. Task Distribution Rules

### Rule 1: Match Task to Agent Strength

| Task Type | Primary Agent | Review Agent |
|---|---|---|
| Bug fix (single file) | OpenCode | Codex (if security) |
| New feature (multi-file) | MiMo | Codex (if security) |
| UI component | OpenCode | MiMo (if complex) |
| API endpoint | OpenCode | Codex (if auth/payments) |
| Database schema | MiMo | Codex |
| Test addition | OpenCode | — |
| Documentation | MiMo | — |
| Deployment script | Hermes | Grok (risk review) |
| Security change | Codex (review) | MiMo (implement) |
| Performance change | MiMo | Codex (review) |
| Monitoring/ops | Hermes | MiMo (verification) |

### Rule 2: P0 Tasks Get Two Agents

For P0 (launch blocker) tasks:
- One agent implements
- One agent reviews
- Both must sign off before task is marked done

### Rule 3: No Agent Works on Unauthorized Scope

Agents must not:
- Start tasks not in the execution backlog
- Modify files outside their working directory
- Skip quality gates
- Deploy to production without explicit approval
- Commit changes without user request

### Rule 4: Task Handoff Protocol

When an agent finishes its part:
1. Document what was done in task comments
2. List files changed
3. List validation commands run and results
4. Pass to review agent if required
5. Only mark done after review passes

---

## 3. Escalation Paths

### Path 1: Agent Blocked

```
Agent blocked → Report blocker to MiMo
MiMo assesses → Reassign, unblock, or escalate to user
```

### Path 2: Security Issue Found

```
Any agent finds security issue → Stop task
→ Report to Codex for review
→ Codex produces severity assessment
→ P0/P1: Escalate to user immediately
→ P2/P3: Add to security backlog, continue other work
```

### Path 3: Deployment Failure

```
Hermes deploys → Smoke test fails
→ Hermes attempts rollback
→ If rollback fails → Escalate to user
→ If rollback succeeds → Grok analyzes failure
→ Fix applied → Redeploy
```

### Path 4: Test Failure

```
Agent runs tests → Tests fail
→ Agent reads error output
→ If test is pre-existing failure → Document and continue
→ If test is new failure → Fix before marking task done
→ If fix is complex → Block task, create new task
```

### Path 5: Architecture Disagreement

```
Agent proposes architecture change
→ MiMo reviews
→ If MiMo agrees → Proceed
→ If MiMo disagrees → Document reasoning
→ If still unclear → Escalate to user
```

---

## 4. Current Sprint Assignment

### Week 1 (Launch Blockers)

| Task | Agent | Review | Status |
|---|---|---|---|
| 1.1 Usage limit enforcement | Codex | MiMo | TODO |
| 1.2 Payment flow E2E | OpenCode | Codex | TODO |
| 1.3 Health check validation | Hermes | MiMo | TODO |

### Week 2 (Product Correctness)

| Task | Agent | Review | Status |
|---|---|---|---|
| 2.1 Finding documentation | MiMo | — | TODO |
| 2.2 Scoring test fixtures | OpenCode | MiMo | TODO |
| 2.3 Rules regression tests | OpenCode | MiMo | TODO |
| 3.1 Executive summary | OpenCode | Codex | TODO |

### Week 3 (Reliability + Conversion)

| Task | Agent | Review | Status |
|---|---|---|---|
| 3.2 Email capture | OpenCode | MiMo | TODO |
| 4.1 Backup automation | Hermes | MiMo | TODO |
| 4.2 Smoke test suite | Hermes | Grok | TODO |

### Week 4 (UX + Security)

| Task | Agent | Review | Status |
|---|---|---|---|
| 3.3 Error pages | OpenCode | MiMo | TODO |
| 3.4 Dashboard stats | MiMo | OpenCode | TODO |
| 5.1 CSP audit | Codex | MiMo | TODO |
| 5.2 Account lockout | Codex | MiMo | TODO |

### Week 5 (Deployment + Observability)

| Task | Agent | Review | Status |
|---|---|---|---|
| 6.1 Deploy script validation | Hermes | MiMo | TODO |
| 6.2 VPS status monitoring | Hermes | Grok | TODO |
| 7.1 Structured logging | MiMo | Codex | TODO |
| 7.2 Prometheus metrics | MiMo | Hermes | TODO |

### Week 6 (Growth)

| Task | Agent | Review | Status |
|---|---|---|---|
| 8.1 SEO content (10 posts) | MiMo | — | TODO |
| 8.2 Agency landing page | OpenCode | MiMo | TODO |
| 8.3 Referral system | MiMo | Codex | TODO |
| 8.4 Monthly reports | MiMo | Hermes | TODO |

---

## 5. Quality Gates by Agent

### All Agents

```bash
# Minimum validation before marking any task done
pnpm lint
pnpm typecheck
pnpm test
```

### MiMo (additional)

```bash
pnpm build
# Verify docs updated if docs changed
```

### OpenCode (additional)

```bash
# Verify no new lint warnings
pnpm lint --max-warnings=0
```

### Codex (additional)

```bash
# Security-specific validation
pnpm test -- --grep "security"
pnpm test -- --grep "auth"
pnpm test -- --grep "csrf"
```

### Hermes (additional)

```bash
# Script validation
bash -n scripts/<script>.sh  # Syntax check
bash scripts/<script>.sh --dry-run  # Dry run if supported
```

### Grok (additional)

```bash
# Risk report must include:
# - Failure scenarios
# - Severity assessment
# - Mitigation recommendations
# - Rollback plan
```

---

## 6. Communication Protocol

### Between Agents

Agents do not communicate directly. All coordination goes through:
1. Task comments (in the task management system)
2. File changes (commit messages, PR descriptions)
3. MiMo as orchestrator (for cross-agent coordination)

### With User

- Agents report status at task completion
- Escalation to user only for P0 issues or blocked tasks
- User approval required for: production deployment, git push, database migrations, destructive operations

### Status Updates

Each agent provides at task completion:
- Summary of what was done
- Files changed
- Validation results
- Any blockers or risks
- Next recommended action (if applicable)
