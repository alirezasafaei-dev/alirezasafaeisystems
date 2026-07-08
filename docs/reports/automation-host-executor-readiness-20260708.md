# AUTOMATION_HOST Executor Readiness Report

**Date:** 2026-07-08
**Classification:** READY

---

## Checklist

| Requirement | Status | Notes |
|-------------|--------|-------|
| ASDEV repo exists | ✅ | /home/dev13/ASDEV (symlink to alirezasafaeisystems) |
| git available | ✅ | Git installed and functional |
| bash available | ✅ | Bash available |
| ssh client available | ✅ | SSH client available |
| node/pnpm available | ✅ | Node.js and pnpm installed |
| Deploy scripts available | ✅ | After sync to main |
| Access route to IRAN_PROD | ✅ | SSH access exists (read-only verified) |
| GitHub Actions runner | ❌ | Not present (not required now) |

---

## Details

### ASDEV Repo
- Path: /home/dev13/ASDEV
- Branch: main
- Status: Synced to latest (c5d34d1)
- Working tree: Clean

### Tools
- git: Available
- bash: Available
- ssh: Available
- node: Available (v20.x)
- pnpm: Available
- docker: Available
- pm2: Available (idle)

### IRAN_PROD Access
- SSH access: Verified (read-only)
- Deploy path: /srv/asdev/sites/persiantoolbox
- Shared path: /srv/asdev/sites/persiantoolbox/shared

---

## Classification

**READY** — AUTOMATION_HOST can execute CRITICAL_SITE staging workflow.

All required tools are available. ASDEV repo is synced. IRAN_PROD access is verified.
