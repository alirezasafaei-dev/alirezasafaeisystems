# Security Hardening Audit — Safe / Non-Destructive

**Date:** 2026-07-08  
**Scope:** AUTOMATION_HOST + repo hygiene  
**Mode:** Audit only — no firewall changes, no key rotation, no prod mutation  

---

## Findings

| Area | Result | Severity | Action |
|------|--------|----------|--------|
| Secrets in git | Use `scripts/scan-secrets.sh` before commits | Process | keep |
| Private env | `ASDEV_PRIVATE/` outside git | OK | keep |
| SSH key for IRAN | present local (`asdev_vps_ed25519`) | OK | never commit |
| CODEOWNERS | expanded for control-plane/governance | OK | done this PR |
| Docker exited leftovers | halo-secret*, anonymous exited | Low | archive inventory; no rm |
| PM2 | empty | OK | policy documented |
| Dependency audit | GHA workflow `dependency-audit.yml` / `security-audit.yml` exist | Info | do not thrash CI |
| Host SSH config | not modified | Info | review later with owner |
| Desktop colocation | human browser + gateways on same host | Medium | accept / split later |

---

## Recommendations (safe next)

1. Weekly `bash scripts/scan-secrets.sh` on dirty tree  
2. Ensure `.env*` in all relevant gitignores  
3. Prefer deploy dry-run before any phrase-gated action  
4. Do not store tokens in agent memory docs  

## Explicit non-actions

- No fail2ban/firewall changes  
- No force key rotation  
- No docker prune  
- No production secret rewrite  

```
SECURITY_AUDIT=PASS_WITH_NOTES
DESTRUCTIVE=NONE
```
