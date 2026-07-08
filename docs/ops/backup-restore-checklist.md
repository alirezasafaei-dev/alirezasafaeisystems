# Backup Restore Checklist — CRITICAL_SITE (Meta)

**Last Updated:** 2026-07-08  
**Mode:** Verification drill (non-destructive)  
**Not for:** overwriting live production without incident command

---

## Pre-checks

- [ ] Production healthy on `:3100` (or documented down for true restore)  
- [ ] Newest backup listed under `/srv/asdev/backups/persiantoolbox/`  
- [ ] Operator knows this is **meta** restore (release pointer / metadata), not full DB  
- [ ] Scratch path available: `/srv/asdev/restore-drill/<id>/`  

---

## Drill steps (safe)

```bash
ARCH=$(ls -1t /srv/asdev/backups/persiantoolbox/*.tar.gz | head -1)
DRILL=/srv/asdev/restore-drill/$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$DRILL"
tar -tzf "$ARCH" | head
tar -xzf "$ARCH" -C "$DRILL"
test -f "$DRILL/release.meta"
grep -E '^(release_id|commit|runtime_port|environment)=' "$DRILL/release.meta"
# Expect: environment=production, runtime_port=3100, commit starts with fcc7192…
```

- [ ] `tar -tzf` lists expected files  
- [ ] `release.meta` extracts  
- [ ] commit matches frozen pin (or expected pin)  
- [ ] `current.link` points at known release id  

## Pass / fail

| Result | Criteria |
|--------|----------|
| **PASS** | archive readable + meta fields coherent |
| **FAIL** | corrupt archive, missing meta, wrong env/port |

Record: `docs/reports/backup-restore-drill-latest.md`

---

## True recovery (incident — not this checklist alone)

1. Prefer redeploy frozen/approved pin with production phrase  
2. If multi-release exists: `asdev-rollback.sh` symlink path  
3. Only then consider restoring shared env from **encrypted** offsite (owner)  
4. Public edge restore separate (`APPROVE_CRITICAL_SITE_PUBLIC_EDGE`)  

---

## Explicit non-actions

- Do not `rm` live `releases/` during drill  
- Do not change crontab during drill  
- Do not include unencrypted secrets in git reports  
