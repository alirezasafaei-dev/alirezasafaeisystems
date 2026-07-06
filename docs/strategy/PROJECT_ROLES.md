# ASDEV Project Roles

**Last Updated:** 2026-07-06

Official classification for all repositories in the ASDEV ecosystem.

---

## Live / Primary

### 1. AuditSystems — ASDEV Audit Platform

| Field | Value |
|---|---|
| **Role** | Primary revenue product |
| **Domain** | https://audit.alirezasafaeisystems.ir/ |
| **Repository** | https://github.com/alirezasafaei-dev/auditsystems |
| **Local path** | `sites/live/auditsystems` |
| **Status** | Live / focus |
| **Strategic label** | ASDEV Audit Platform |

**Supports:** submitted audits, report quality, paid conversion, production reliability.

---

### 2. AlirezaSafaeiSystems — ASDEV parent brand

| Field | Value |
|---|---|
| **Role** | Parent ASDEV brand, trust hub, case studies, lead capture, project map |
| **Domain** | https://alirezasafaeisystems.ir/ |
| **Repository** | https://github.com/alirezasafaei-dev/alirezasafaeisystems |
| **Local path** | `sites/live/alirezasafaeisystems` |
| **Status** | Mother repo / brand shell + live portfolio site |

**Supports:** trust, lead qualification, analytics hub, ASDEV governance docs.

This repo holds strategy and agent rules. It is **not** a dumping ground for all product code.

---

### 3. PersianToolbox — Traffic engine

| Field | Value |
|---|---|
| **Role** | Traffic engine and soft lead source |
| **Domain** | https://persiantoolbox.ir/ |
| **Repository** | https://github.com/alirezasafaei-dev/persiantoolbox |
| **Local path** | `sites/live/persiantoolbox` |
| **Status** | Maintain and route qualified traffic to ASDEV Audit |

**Supports:** acquisition, SEO traffic, product proof, CTA routing to audit.

---

## Showcase

### 4. alirezasafaei-dev — GitHub profile

| Field | Value |
|---|---|
| **Role** | GitHub profile and public project showcase |
| **Repository** | https://github.com/alirezasafaei-dev/alirezasafaei-dev |
| **Status** | Lightweight, public-facing, non-operational |

**Contains:** who I am, what ASDEV is, live projects, links, short positioning.

**Must not contain:** deployment runbooks, secrets, agent factory internals, frozen backlog detail.

---

## Hold / Future module

### 5. DevAtlas — Code Audit / Repo Intelligence (future)

| Field | Value |
|---|---|
| **Role** | Future premium Code Audit / Repo Intelligence module |
| **Repository** | https://github.com/alirezasafaei-dev/devatlas |
| **Local path** | `sites/hold/devatlas` (target — currently misplaced in `sites/live/`) |
| **Status** | Hold until ASDEV Audit has traction |

**Rule:** Must not be treated as standalone focus. May integrate into ASDEV Audit as a paid module later.

---

## Secondary / Hold

| Project | Role | Status | Notes |
|---|---|---|---|
| `creatormembership` | Gated membership experiment | Hold | No active investment |
| `microcatalog` | Seller catalog MVP concept | Hold | Market validation incomplete |
| `rubika-bot-saas` | Messaging bot SaaS | Secondary | Frozen |
| `novax-price-alert` | Market alert product | Secondary | Was wrongly promoted to `sites/live/` |
| `halo-secret` | Experimental project | Secondary | Frozen |

**Rule:** Do not delete product repos unless explicitly instructed. Current deletion scope is limited to meta-repo and obsidian vault after confirmed migration.

---

## Deprecated / transitional

| Repo | Former role | Action |
|---|---|---|
| `alirezasafaei-dev-meta-repo` | Cross-project ops super-repo (`~/my-project`) | Migrate strategy → mother repo; archive |
| `safaei-obsidian-vault` | Obsidian knowledge OS | Migrate useful docs; archive |