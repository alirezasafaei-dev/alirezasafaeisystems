# Workspace Reclassification Plan

**Date:** 2026-07-06  
**Status:** Prepared — moves not executed  
**Authority:** [WORKSPACE_STRUCTURE.md](WORKSPACE_STRUCTURE.md)

---

## Required moves

| # | Project | From | To | Git impact |
|---|---|---|---|---|
| 1 | `devatlas` | `sites/live/devatlas` | `sites/hold/devatlas` | Independent repo; update path refs in docs/scripts |
| 2 | `novax-price-alert` | `sites/live/novax-price-alert` | `sites/secondary/novax-price-alert` | Independent repo; remove from live README tables |

---

## Pre-move checklist

For each directory:

```bash
cd sites/live/<project>
git status                    # must be clean or changes committed
git remote -v                 # confirm correct remote
# after move:
grep -r "sites/live/<project>" ~/my-project --include="*.md" --include="*.sh"
```

---

## Files to update after moves

| File | Change |
|---|---|
| `~/my-project/README.md` | Remove devatlas/novax from live table |
| `~/my-project/IMPLEMENTATION-STATUS.md` | Reclassify devatlas, novax |
| `~/my-project/DEPLOYMENT_RULES.md` | Mark devatlas deploy as hold-only |
| `scripts/deploy-vps.sh` | Verify prepare targets |
| `deploy/registry.tsv` | Tier annotation |

Mother repo docs already reflect target structure.

---

## Do not move yet

- `shared/` — cross-project packages stay at root
- `deploy/` — stays in meta-repo workspace until owner decides workspace fate
- Product repos themselves — only directory location changes, not git history

---

## Execution command (when approved)

```bash
# Example — run only after git status check
git mv sites/live/devatlas sites/hold/devatlas
git mv sites/live/novax-price-alert sites/secondary/novax-price-alert
```

Then update references and run workspace guard script if available.