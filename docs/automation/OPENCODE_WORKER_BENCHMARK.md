# OpenCode Worker Benchmark

**Date:** 2026-07-06
**Version:** v1.17.13
**Model:** deepseek-v4-flash-free

---

## Test: Read-Only Script Review

**Task:** Review command loop scripts for brittleness, error handling, unsafe assumptions, portability

**Input:**
- `scripts/agent-command-center/monitor-command-thread.sh`
- `scripts/agent-command-center/run-command-loop.sh`

**Output Quality:** ✅ Good

### Findings

| Category | monitor-command-thread.sh | run-command-loop.sh |
|---|---|---|
| Brittleness | High — jq on empty input | Medium — grep/awk parsing |
| Error handling | Severe — no gh/jq checks | Medium — no existence check |
| Unsafe assumptions | Medium — jq regex, null handling | Medium — output format parsing |
| Portability | Medium — pipefail, jq 1.6+ | Low — mostly POSIX |

### Applied Fixes

1. ✅ Added numeric validation for --issue/--pr args
2. ✅ Documented brittleness concerns

### Deferred Fixes

1. JSON-based status output (requires monitor rewrite)
2. gh/jq existence checks (add later)
3. Empty response guards (add later)

---

## Test: Read-Only Project Inspection

**Task:** Read automation README and summarize

**Result:** ✅ Working

```
opencode run "Read docs/automation/README.md and summarize in 3 lines"
```

Output: Accurate 3-line summary.

---

## Assessment

| Metric | Score |
|---|---|
| Read-only inspection | ✅ Excellent |
| Code review quality | ✅ Good |
| Safe feedback | ✅ Yes |
| Would trust for drafts | ⚠️ With supervision |
| Would trust for production | ❌ Not without review |

---

## Recommendation

OpenCode is suitable for:
- Read-only code inspection
- Draft implementations (with review)
- Documentation generation
- Alternate model coverage

Not suitable for:
- Direct production commits
- PersianToolbox modifications
- Autonomous merge decisions

---

*Benchmark complete. OpenCode validated as useful worker.*
