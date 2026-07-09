# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-09T21:00:00Z  
**Status:** AUTO_LOOP_ON · MULTI_AGENT (mimo+opencode) · COMPLETE_WORK_FIRST · DEPLOY_LAST  
**Machine queue:** `control-plane/queue/queue.json`  
**Orchestration:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`

---

## Live

| Layer | State |
|-------|-------|
| GitHub platform main | multi-agent orchestration docs + loop policy |
| Product GitHub | `d0ae88f` (+ inspect scrub) ahead of public live `37ba347` |
| Public VPS | LIVE green ~`37ba347` · edge ON public |
| ASDEV IRAN app-layer | `:3100` separate |
| Deploy | **LAST** — only when phase ready; not mid-quality |

---

## Queue

### Safe / continuous (AUTO LOOP)
- [x] Multi-agent local orchestration doc
- [x] deploy-blue-green inspect scrub (product main)
- [ ] Harvest mimo quality gap report → merge accepted fixes
- [ ] Harvest opencode SEO gaps → merge accepted fixes
- [ ] P4 SEO/GSC (meta, internal links, sitemap warnings) without claiming 10/10
- [ ] P4b blog editorial polish remaining (B5–B8)
- [ ] P5 a11y form labels sitewide (pattern from mimo)
- [ ] Pre-deploy QA gate green (typecheck/lint/vitest) before any cutover

### Gated (owner phrase still required for edge/prod mutation beyond product release path)
| Theme | Phrase |
|-------|--------|
| Public edge mutation | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Live timers | `APPROVE_MONITORING_LIVE_TIMERS` |
| Migrations | `APPROVE_CRITICAL_SITE_MIGRATION` |
| Prod cutover when phase ready | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` (or owner auto-scope) |

---

## NEXT_AUTONOMOUS_ACTION

Continue multi-agent safe product quality; harvest worker branches; no public deploy until complete-work gate.
