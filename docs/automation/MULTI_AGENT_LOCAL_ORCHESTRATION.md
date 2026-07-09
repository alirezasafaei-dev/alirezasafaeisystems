# Multi-Agent Local Orchestration — OWNER_PC

**Status:** ACTIVE (2026-07-09)  
**Host:** OWNER_PC / AUTOMATION_HOST colocated (`/home/dev13`)  
**Orchestrator:** Grok (this session) under `ASDEV_AUTONOMOUS_LOOP_POLICY.md`  
**Mode:** `AUTO LOOP ON` · complete work first · deploy last

---

## Installed assistants (this machine)

| Binary | Path | Role in multi-agent |
|--------|------|---------------------|
| **mimo** (MiMoCode) | `mimo` via fnm | Primary parallel assistant — audit, docs, bounded product drafts |
| **opencode** | `~/.opencode/bin/opencode` | Code worker — SEO/tech gaps, alternate review, drafts |
| **gemini** | `~/.npm-global/bin/gemini` | Optional second opinion / research |
| **hermes** | `~/.local/bin/hermes` | Control-plane / profiles / cron gateway |
| **openclaw** | `~/.npm-global/bin/openclaw` | Ops gateway (outside PM2) |

Owner preference for **start of multi-agent**: **mimo + opencode**.

---

## How the orchestrator runs them

### Non-interactive (preferred under AUTO LOOP)

```bash
# MiMo — never ask; auto-approve tool use for bounded missions
mimo run --dir <worktree_or_repo> \
  --title "<mission-id>" \
  --dangerously-skip-permissions \
  "MISSION: ... Hard stop: ... Do NOT deploy. Do NOT push unless told."

# OpenCode — auto-approve for bounded missions
opencode run --dir <worktree_or_repo> \
  --title "<mission-id>" \
  --auto \
  "MISSION: ... Hard stop: ... Do NOT deploy. Do NOT push unless told."
```

### Isolation

| Pattern | When |
|---------|------|
| **git worktree + branch** | Any product write mission |
| **read-only prompt** | Audits, reviews, GSC analysis |
| **main checkout (orchestrator)** | Grok applies accepted patches, final commits, push |

Example worktrees:

```text
worktrees/pt-mimo-audit      → branch agent/mimo-quality-audit
worktrees/pt-opencode-seo    → branch agent/opencode-seo-gaps
```

### Parallel logs

```text
/tmp/asdev-multiagent/mimo.log
/tmp/asdev-multiagent/opencode.log
```

---

## Safety (non-negotiable)

Workers **must not**:

1. Deploy production / nginx / SSL / DNS  
2. Print or commit secrets / `.env`  
3. Force-push or amend published history  
4. Claim product score **10/10** without evidence checklist  
5. Mutate live hosts without owner production phrases  

Workers **may** (when mission says so):

- Write audit docs under `docs/audits/`  
- Small safe product fixes on **agent/*** branches  
- Local commit on branch; **push only if orchestrator merges/accepts**

Production mutations still need exact phrases in `APPROVAL_GATES.md`.

---

## Mission template

```text
You are <MIMO|OPENCODE> under Grok orchestrator (ASDEV AUTO LOOP).
Repo: <path> · Branch isolation only.
MISSION: <3–6 concrete steps>
OUT: <file path for report and/or patch>
FORBIDDEN: deploy, secrets, push to main, production SSH
HARD STOP: when report written (+ optional one small fix)
END: SUMMARY block
```

---

## Integration with loop policy

After each worker finishes:

1. Orchestrator reads report / diff  
2. Cherry-pick or re-implement accepted changes on product/platform main  
3. Validate (typecheck/test as applicable)  
4. Commit in logical batches · push  
5. Select next highest-value safe task  
6. Re-dispatch workers if parallel ROI remains  

See also:

- `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`  
- `docs/automation/MIMO_AGENT_PROFILES.md`  
- `docs/automation/OPENCODE_WORKER.md`  
- `docs/automation/BACKGROUND_AGENT_ACTIVATION.md`  

**Note:** Older docs marked PersianToolbox **read-only** for workers. Owner override for this loop: workers may edit **only** in isolated worktrees under orchestrator missions; production deploy remains gated.
