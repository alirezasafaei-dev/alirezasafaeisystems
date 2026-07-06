# PersianToolbox — Traffic Engine

**Role:** Traffic engine and soft lead source  
**Status:** Live / maintain  
**Domain:** https://persiantoolbox.ir/  
**Repository:** https://github.com/alirezasafaei-dev/persiantoolbox  
**Local path:** `sites/live/persiantoolbox`

---

## Case study — PersianToolbox local-first traffic engine

### Problem

Persian-speaking users need fast, private utility tools (PDF, finance, text) without installing apps or uploading sensitive files — while ASDEV needs qualified paths to website audit.

### Constraints

- Local-first promise must not be weakened by aggressive cross-sell
- No new tools in Phase 1 trust work
- Audit is a **different product** (URL-based, not file-based)
- Premium/billing deferred until Audit revenue MVP

### Architecture / approach

- Central tools registry with generated SEO routes (46+ tools)
- Browser-local processing for file/category tools
- Consent-gated self-hosted analytics
- Intent-based CTA registry (`lib/cta-registry.ts`) with UTM attribution
- Trust page (`/trust`) explaining data classes and network behavior
- Phase 2 template doc for high-value tool pages (`docs/growth/HIGH_VALUE_TOOL_TEMPLATE.md`)

### Production evidence

| Item | Status |
|---|---|
| Live domain | `persiantoolbox.ir` |
| Trust / transparency page | `/trust` |
| CTA registry with audit routing | `audit-free-check` → sample report |
| Local-first architecture doc | `docs/technical/01-Architecture/01-local-first-architecture.md` |

### What was measured

- Tool count and registry structure: documented in repo
- Audit conversion from toolbox UTM: **Evidence pending**

### What is not claimed

- No MAU/DAU figures
- No revenue from toolbox premium
- No claim that toolbox tools audit websites

### Links

- Live: https://persiantoolbox.ir/
- Trust: https://persiantoolbox.ir/trust
- Repo: https://github.com/alirezasafaei-dev/persiantoolbox
- Audit sample (from toolbox CTAs): https://audit.alirezasafaeisystems.ir/sample-report?utm_source=toolbox

### CTA

Soft audit routing on trust page, finance CTAs, homepage trust section — never intrusive popups.

---

## Agent rules

- New high-value tool pages follow `docs/growth/HIGH_VALUE_TOOL_TEMPLATE.md`
- Contextual Audit CTA where business/website intent is plausible
- Do not build standalone monetization competing with Audit focus

## Links

- [Master roadmap](../strategy/ASDEV_AUDIT_MASTER_ROADMAP.md) Phase 2
- [Phase 2 tool template](../../persiantoolbox/docs/growth/HIGH_VALUE_TOOL_TEMPLATE.md) (in product repo)
- Product docs: `sites/live/persiantoolbox/DOCUMENTATION.md`