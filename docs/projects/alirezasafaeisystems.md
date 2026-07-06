# AlirezaSafaeiSystems — ASDEV Mother / Brand Site

**Role:** Portfolio, trust hub, case studies, lead qualification  
**Status:** Live / maintain  
**Domain:** https://alirezasafaeisystems.ir/  
**Repository:** https://github.com/alirezasafaei-dev/alirezasafaeisystems  
**Local path:** `sites/live/alirezasafaeisystems`

---

## Case study — ASDEV brand and governance site

### Problem

ASDEV needed a single credible surface for:

- Explaining who builds the products
- Routing serious inquiries without fake "large team" positioning
- Holding strategy, roadmap, and project roles in one place

### Constraints

- Solo-operator reality — no invented team or hiring pipeline
- Must not compete with Audit for primary conversion
- Strategy docs must stay separate from product runtime code

### Architecture / approach

- Next.js portfolio app + `docs/strategy/` governance layer
- Qualification route for scoped professional review requests
- Cross-links to Audit sample report and Audit start as primary product path
- Project role matrix in `docs/strategy/PROJECT_ROLES.md`

### Production evidence

| Item | Status |
|---|---|
| Live domain | `alirezasafaeisystems.ir` |
| Strategy docs in repo | `docs/strategy/`, `docs/projects/` |
| Qualification / inquiry route | `/qualification` |
| Analytics client (consent-aware) | `src/lib/analytics/client.ts` |

### What was measured

- Measurement not yet public-safe for traffic, conversion, or inquiry volume

### What is not claimed

- No revenue figures
- No customer count or logo wall
- No "we are hiring" unless owner explicitly approves

### Links

- Live: https://alirezasafaeisystems.ir/
- Repo: https://github.com/alirezasafaei-dev/alirezasafaeisystems
- Primary product: https://audit.alirezasafaeisystems.ir/sample-report

### CTA

Professional review and project inquiries → qualification form; product evaluation → ASDEV Audit sample report.