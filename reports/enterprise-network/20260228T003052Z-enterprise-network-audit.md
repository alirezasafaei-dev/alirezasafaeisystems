# Enterprise Network Audit Report

- Generated at: 2026-02-28T00:30:52.346Z
- Scope: https://alirezasafaeisystems.ir | https://audit.alirezasafaeisystems.ir | https://persiantoolbox.ir

## Site Results

### portfolio (https://alirezasafaeisystems.ir)
- Role: conversion_engine
- Root status: 200
- Ready status: 200
- Score: 83 (5 pass / 1 fail)

| Check | Status | Detail |
|---|---|---|
| html_locale | PASS | lang=fa dir=rtl |
| title | PASS | length=51 |
| meta_description | PASS | length=174 |
| canonical | PASS | https://alirezasafaeisystems.ir/fa/ |
| cross_link_audit | PASS | expects audit cross-link |
| cross_link_toolbox | FAIL | expects toolbox cross-link |

### audit (https://audit.alirezasafaeisystems.ir)
- Role: qualification_engine
- Root status: 200
- Ready status: 200
- Score: 89 (8 pass / 1 fail)

| Check | Status | Detail |
|---|---|---|
| html_locale | PASS | lang=fa dir=rtl |
| title | PASS | length=32 |
| meta_description | PASS | length=79 |
| canonical | PASS | https://audit.alirezasafaeisystems.ir |
| cross_link_portfolio | PASS | expects portfolio cross-link |
| cross_link_toolbox | FAIL | expects toolbox cross-link |
| footer_clean_old_network | PASS | legacy network footer section must be removed |
| footer_clean_badges | PASS | legacy footer badges must be removed |
| footer_clean_old_bottom | PASS | legacy footer-bottom block must be removed |

### toolbox (https://persiantoolbox.ir)
- Role: acquisition_engine
- Root status: 200
- Ready status: 200
- Score: 100 (5 pass / 0 fail)

| Check | Status | Detail |
|---|---|---|
| html_locale | PASS | lang=fa dir=rtl |
| title | PASS | length=28 |
| meta_description | PASS | length=73 |
| canonical | PASS | https://persiantoolbox.ir |
| cross_link_portfolio | PASS | expects portfolio link |

## Phase Actions

| Priority | Phase | Action |
|---|---|---|
| HIGH | Phase 3: Information Architecture Refactor | Repair missing cross-site intent links to keep acquisition -> qualification -> conversion path intact. |
