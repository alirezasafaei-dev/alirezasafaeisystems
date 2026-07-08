# Security Baseline — ASDEV

**Updated:** 2026-07-08  
**Mode:** Baseline policy + audit posture (non-destructive)

---

## Controls

| Control | Requirement | Status |
|---------|-------------|--------|
| Secrets in git | Never; scan before commit | process + `scripts/scan-secrets.sh` |
| Private env | `ASDEV_PRIVATE/` only | OK |
| SSH keys | local agent key; never commit | OK |
| CODEOWNERS | protected platform paths | expanded |
| Approval gates | minimal irreversible set | documented |
| Deploy dry-run | default without phrase | engine |
| Docker leftovers | inventory; no blind rm | documented |
| Dependencies | GHA security/dependency workflows exist | do not thrash |
| Reports | aliases only; no raw secrets | policy |

---

## SSH posture (policy)

- Prefer key auth, disable password where possible (host-level owner change)  
- Separate keys per role when practical  
- IRAN access limited to ops user  

## Permission review

| Path | Expectation |
|------|-------------|
| shared env on IRAN | 600, owner deploy user |
| release dirs | immutable after activate |
| backup roots | not world-readable if secrets ever included |

## Vulnerability process

1. Dependabot / audit workflows signal  
2. Agent triages severity  
3. Patch in PR; no silent force  

## Explicit non-actions in baseline passes

- No firewall mutation without owner  
- No mass secret rotation without plan  
- No production secret printing  

Related: `docs/reports/security-hardening-audit-latest.md`
