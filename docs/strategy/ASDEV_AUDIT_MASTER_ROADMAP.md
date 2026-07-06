# ASDEV Audit Master Roadmap

**Model:** Dependency-driven phases — no calendar promises  
**Authority:** Canonical roadmap for the ASDEV ecosystem  
**Product:** ASDEV Audit Platform (`auditsystems`)  
**Last Updated:** 2026-07-06

---

## Vision

ASDEV Audit Platform is the primary revenue product. PersianToolbox acquires traffic. AlirezaSafaeiSystems builds trust and qualifies demand. Everything else is frozen until Audit proves traction.

**Differentiation:** Accurate, trusted technical audits with actionable reports — backed by live production proof across the ASDEV network.

---

## Phase 0: Truth, Privacy, Observability

**Outcome:** Claims match reality; funnel is measurable.

| ID | Task | Surface | Gate |
|---|---|---|---|
| E0-01 | Align account availability, navigation, privacy copy | Toolbox / All | UI, flags, policy describe same behavior |
| E0-02 | Consolidate consent-aware cross-site analytics | Shared | One contract, consent dispatch, graceful failure |
| E0-03 | Prove funnel attribution | All | Toolbox CTA → destination event correlated |
| E0-04 | Portfolio PostgreSQL migration plan | Portfolio | Backup, migration, validation, rollback documented |
| E0-05 | Production evidence baseline | All | Live commit, health, worker, crawl, event checks |

**Status:** Largely verified per meta-repo task registry. E0-04 production run requires approval.

---

## Phase 1: Trust and Conversion

**Outcome:** Users inspect proof and reach the correct Audit offer.

| ID | Task | Surface | Gate |
|---|---|---|---|
| E1-01 | Credible sample report page | Audit | Anonymized findings, severity, CTA |
| E1-02 | Intent-based CTA registry | All | Stable placement/offer IDs |
| E1-03 | Local-first trust page | Toolbox | Data flow, network disclosure |
| E1-04 | Product case studies with evidence | Portfolio | Measured metrics, architecture diagrams |
| E1-05 | Hiring path | Portfolio | Owner-approved roles and inquiry route |

**Audit-first priority:** E1-01 and E1-02 directly drive audit submissions.

---

## Phase 2: High-Intent Organic Growth

**Outcome:** Iranian work clusters become authoritative and route to Audit.

| ID | Task | Surface | Gate |
|---|---|---|---|
| E2-01 | Standardize high-value tool template | Toolbox | Tool, trust, FAQ, schema, contextual Audit CTA |
| E2-02 | HR/administrative cluster | Toolbox | Interlinked salary, tax, insurance pages |
| E2-03 | Administrative PDF cluster | Toolbox | Government/hiring use cases → file tools |
| E2-04 | Formula freshness evidence | Toolbox | Source, version, effective date visible |

**Rule:** Every new Toolbox page must answer how it routes qualified traffic to ASDEV Audit.

---

## Phase 3: Revenue MVP

**Outcome:** One paid Audit outcome works end-to-end.

| ID | Task | Surface | Gate |
|---|---|---|---|
| E3-01 | Professional export pilot | Toolbox | Tested artifact, clear free/paid boundary |
| E3-02 | Productized Audit offer | Audit + Portfolio | Scope, exclusions, delivery, qualification |
| E3-03 | Activate one payment path | Audit | Sandbox E2E, verified callback, reconciliation |
| E3-04 | Measure conversion funnel | All | View → lead → payment reportable |

**Blockers:** E3-02 and E3-03 blocked on owner pricing/merchant decisions.

---

## Phase 4: B2B Validation

**Outcome:** One API/widget pilot proves partner value.

| ID | Task | Surface | Gate |
|---|---|---|---|
| E4-01 | API/widget discovery page | Toolbox | Concrete use cases, interest form |
| E4-02 | One API/widget pilot | Toolbox | Versioned contract, auth, quota, design partner |
| E4-03 | B2B case study | Portfolio | Measured result, public-safe architecture |

---

## Deferred until Audit traction

See [`FROZEN_BACKLOG.md`](FROZEN_BACKLOG.md):

- DevAtlas standalone product
- Novax / Rubika / MicroCatalog / CreatorMembership expansion
- Broad premium gating before one paid Audit outcome works
- AI tool suite, native ads, affiliate inventory
- White-label enterprise infrastructure

---

## Governance

| Document | Role |
|---|---|
| This file | Outcomes and dependencies |
| Meta-repo `docs/execution/task-registry.md` | Task status until migrated here |
| `FOCUS_POLICY.md` | Agent rejection rules |
| `PROJECT_ROLES.md` | Repository classification |
| Product `DOCUMENTATION.md` files | Implementation detail |

---

## Weekly review questions

1. Did audit submissions increase?
2. Did report trust/quality improve?
3. Did Toolbox → Portfolio → Audit attribution hold?
4. What work did not support Audit goals? → freeze it.