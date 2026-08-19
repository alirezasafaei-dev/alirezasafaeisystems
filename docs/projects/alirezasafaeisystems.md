# AlirezaSafaeiSystems — ASDEV Mother / Brand Site

**Role:** Portfolio, trust hub, owned resource hub, acquisition, case studies, lead qualification  
**Status:** Live / maintain + Discover Resource Hub implementation in PR #183; production verification remains owner-gated  
**Domain:** https://alirezasafaeisystems.ir/  
**Repository:** https://github.com/alirezasafaei-dev/alirezasafaeisystems  
**Local path:** `sites/live/alirezasafaeisystems`

---

## Discover — owned content and resource hub

`/discover` is the stable ASDEV destination for people arriving from Instagram, search or direct links who need an official tool destination, a short practical explanation, a complete Telegram tutorial/file, or a place to ask follow-up questions. It remains part of the existing ASDEV application rather than becoming a separate product, service, database or deployment target.

### Product flow

`Instagram / Search / Direct → /discover → /discover/[slug] → quick guide → official destination and/or exact Telegram tutorial/file → optional community discussion`

Secondary ASDEV navigation remains available after the resource task. Audit, Case Studies and Qualification must not interrupt the visitor before the promised resource is delivered.

### Architecture

- Same Next.js application, site shell, locale handling and deployment contract.
- Dedicated Prisma `DiscoverItem` model in the existing SQLite database.
- Existing Admin authentication and rate limiting; no parallel auth.
- Dedicated Discover CRUD manager inside the current Admin content surface.
- Published-only public landing/detail queries.
- Search and category filtering on the landing page.
- `content` stores the short practical guide rendered on ASDEV.
- `externalUrl` stores the official third-party destination.
- optional `telegramGuideUrl` stores one exact `https://t.me/...` tutorial/file deep link per item and remains editable through Admin without redeploy.
- optional `NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL` and `NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL` expose global channel/community continuation only when configured.
- no Instagram DM/comment automation and no Telegram Bot API are required.
- UTM attribution preserves only `utm_source`, `utm_medium`, `utm_campaign`, and `utm_content` across internal ASDEV navigation; external official/Instagram/Telegram URLs never receive those parameters.
- consent-aware analytics records landing/detail views plus distinct official, Telegram guide, Telegram channel, Telegram group and internal CTA events.
- published detail pages remain in the dynamic sitemap when the content DB is reachable.

### Legacy compatibility

The earlier implementation stored Discover records in `Project(contentType=discover)`. The dedicated Discover migration copied those records into `DiscoverItem` with stable `legacy-*` slugs and left all original Project rows untouched for history/rollback. New Discover content belongs in `DiscoverItem` only.

The Resource Hub evolution adds only nullable `DiscoverItem.telegramGuideUrl`; existing records remain valid without a Telegram resource.

### Content operating model

For each Instagram Reel/Post:

1. create or update the matching Discover item;
2. verify the official HTTPS destination;
3. keep the on-site quick guide concise and useful;
4. when long-form training or a file is needed, publish it to the Telegram channel;
5. store the exact Telegram message URL in `telegramGuideUrl`;
6. publish the Discover item;
7. route the Instagram audience through the single Bio `/discover` link and tell them what title/category to search;
8. use the Telegram group for discussion/Q&A, not as the canonical archive.

### Governance

Discover is an owned distribution/resource surface. Its first responsibility is fulfilling the visitor's resource intent safely and predictably. Secondary ASDEV acquisition/lead routing is allowed only after that primary task.

Production deployment and production database migration remain explicit owner approval gates. A merged source change or green CI run is not sufficient production evidence.

### Implementation status — 2026-08-19

- The original Discover acquisition implementation was merged in PR #133.
- Locale, deployment-smoke and production SQLite hardening followed through PR #167 and subsequent migration/deploy fixes.
- The Resource Hub evolution is specified in `docs/superpowers/specs/2026-08-19-discover-resource-hub-design.md`.
- The agent-executable implementation plan is `docs/superpowers/plans/2026-08-19-discover-resource-hub.md`.
- Roadmap issue: #174; implementation tasks: #175–#182.
- Implementation work is isolated in draft PR #183 until exact-head verification and final rollout gating are complete.
- Production completion requires deployed-route, migration-status, zero-drift and live smoke evidence; it must not be inferred from source state alone.

### Implementation references

- `docs/superpowers/specs/2026-08-15-discover-acquisition-surface-design.md` — historical acquisition design
- `docs/superpowers/plans/2026-08-15-discover-acquisition-surface.md` — historical implementation plan
- `docs/superpowers/specs/2026-08-19-discover-resource-hub-design.md` — current Resource Hub design
- `docs/superpowers/plans/2026-08-19-discover-resource-hub.md` — current agent execution plan
- `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`

---

## Case study — ASDEV brand and governance site

### Problem

ASDEV needed a single credible surface for:

- Explaining who builds the products
- Routing serious inquiries without fake "large team" positioning
- Holding strategy, roadmap, and project roles in one place
- Converting social discovery into owned traffic instead of sending every visitor directly back out to third-party services
- Giving social audiences one stable ASDEV destination for official links, practical guidance and deeper resources

### Constraints

- Solo-operator reality — no invented team or hiring pipeline
- Must not compete with Audit for primary conversion
- Strategy docs must stay separate from product runtime code
- Discover remains an owned support/resource surface rather than a standalone product scope
- Instagram resource delivery should not depend on third-party DM/comment automation

### Architecture / approach

- Next.js portfolio app + `docs/strategy/` governance layer
- Qualification route for scoped professional review requests
- Cross-links to Audit sample report and Audit start as secondary professional-service paths
- Project role matrix in `docs/strategy/PROJECT_ROLES.md`
- Discover Resource Hub inside the same application and Admin
- Telegram used only as an external long-form/file/community destination, not as an application runtime dependency

### Production evidence

| Item | Status |
|---|---|
| Live domain | `alirezasafaeisystems.ir` |
| Strategy docs in repo | `docs/strategy/`, `docs/projects/` |
| Qualification / inquiry route | `/qualification` |
| Analytics client (consent-aware) | `src/lib/analytics/client.ts` |
| Original Discover acquisition implementation | Merged in #133 with later rollout hardening |
| Discover Resource Hub evolution | Implementation in PR #183; production rollout evidence not yet claimed |

### What was measured

- Measurement is not yet public-safe for traffic, conversion or inquiry volume.
- Discover events/UTM attribution create the instrumentation needed for future evidence; they do not justify traffic or conversion claims before real production data exists.
- Resource Hub adds separate Telegram guide/channel/group click events so exact resource use can be distinguished from generic community navigation.

### What is not claimed

- No revenue figures
- No customer count or logo wall
- No invented Discover traffic/conversion numbers
- No claim that Resource Hub is live until post-deploy evidence exists
- No "we are hiring" unless owner explicitly approves

### Links

- Live: https://alirezasafaeisystems.ir/
- Repo: https://github.com/alirezasafaei-dev/alirezasafaeisystems
- Primary product: https://audit.alirezasafaeisystems.ir/sample-report

### CTA

Resource discovery → `/discover`; professional review and project inquiries → qualification form; product evaluation → ASDEV Audit sample report.
