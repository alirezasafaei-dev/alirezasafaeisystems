# ASDEV Autonomous Sprint Types

**Status:** Active
**Date:** 2026-07-08

## Sprint Types

### Type 1: Automation Fix Sprint
- Goal: Fix broken automation/control plane
- Risk: Low
- Merge: Auto after validation
- Deploy: No
- Tasks: Fix bot, fix timer, fix command bus, fix scripts

### Type 2: Production Health Sprint
- Goal: Ensure production is healthy and monitored
- Risk: Low
- Merge: Auto after validation
- Deploy: Yes if health checks pass
- Tasks: Add monitoring, check SSL, verify endpoints, add alerts

### Type 3: Security Hardening Sprint
- Goal: Improve security posture
- Risk: Medium
- Merge: Auto after Codex review
- Deploy: Yes if no breaking changes
- Tasks: CSP nonces, auth hardening, header improvements

### Type 4: Performance Sprint
- Goal: Improve response times and resource usage
- Risk: Medium
- Merge: Auto after validation
- Deploy: Yes if benchmarks pass
- Tasks: Caching, CDN, bundle optimization, DB queries

### Type 5: UX/Live Audit Sprint
- Goal: Fix UX issues found in live audit
- Risk: Low
- Merge: Auto after validation
- Deploy: Yes
- Tasks: Error states, empty states, mobile, forms

### Type 6: SEO/Conversion Sprint
- Goal: Improve SEO and conversion rates
- Risk: Low
- Merge: Auto after validation
- Deploy: Yes
- Tasks: Titles, schemas, CTAs, onboarding

### Type 7: Test Coverage Sprint
- Goal: Improve test coverage and reliability
- Risk: Low
- Merge: Auto after validation
- Deploy: No
- Tasks: Add tests, fix flaky tests, improve coverage

### Type 8: Documentation Sprint
- Goal: Improve documentation and runbooks
- Risk: Low
- Merge: Auto
- Deploy: No
- Tasks: Update docs, add runbooks, improve guides

### Type 9: Growth Backlog Sprint
- Goal: Execute growth tasks from backlog
- Risk: Low-Medium
- Merge: Auto after validation
- Deploy: Yes
- Tasks: SEO content, landing pages, conversion improvements

### Type 10: Emergency Response Sprint
- Goal: Respond to production incident
- Risk: High
- Merge: Manual only
- Deploy: Manual only
- Tasks: Diagnose, fix, rollback, post-mortem
