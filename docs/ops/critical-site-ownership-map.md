# Critical Site Ownership Map

**Document Version:** 1.0
**Last Updated:** $(date -u +"%Y-%m-%d")
**Classification:** INTERNAL - PRODUCTION OPERATIONS

## Overview

This document maps critical production sites to their responsible teams, infrastructure, and operational procedures. **persiantoolbox.ir** is designated as the primary critical site.

## Critical Site: persiantoolbox.ir

### Site Information

| Attribute | Value |
|-----------|-------|
| **Domain** | persiantoolbox.ir |
| **Criticality Level** | CRITICAL |
| **Business Function** | Primary traffic engine and lead source |
| **Revenue Impact** | HIGH |
| **User Impact** | HIGH |
| **Uptime Requirement** | 99.9% |

### Ownership

| Role | Team/Individual | Contact Method | Availability |
|------|-----------------|----------------|--------------|
| **Primary Owner** | [PLACEHOLDER - Team Lead] | [PLACEHOLDER - Email/Slack] | Business Hours |
| **Technical Lead** | [PLACEHOLDER - Tech Lead] | [PLACEHOLDER - Email/Slack] | Business Hours |
| **DevOps Lead** | [PLACEHOLDER - DevOps] | [PLACEHOLDER - Email/Slack] | 24/7 |
| **Security Lead** | [PLACEHOLDER - Security] | [PLACEHOLDER - Email/Slack] | Business Hours |
| **Business Owner** | [PLACEHOLDER - Product] | [PLACEHOLDER - Email/Slack] | Business Hours |

### Infrastructure

| Component | Details |
|-----------|---------|
| **Primary Server** | IRAN_PROD (Inventory script required) |
| **Web Server** | Nginx [PLACEHOLDER - Version] |
| **Application Runtime** | Node.js [PLACEHOLDER - Version] |
| **Process Manager** | PM2 [PLACEHOLDER - Version] |
| **Database** | [PLACEHOLDER - Type/Version] |
| **Cache** | [PLACEHOLDER - Type/Version] |
| **CDN** | [PLACEHOLDER - Provider] |

### SSL/TLS Configuration

| Certificate | Expiry Date | Auto-Renewal | Last Verified |
|-------------|-------------|--------------|---------------|
| [PLACEHOLDER - Domain] | [PLACEHOLDER - Date] | [PLACEHOLDER - Yes/No] | [PLACEHOLDER - Date] |

### Backup & Recovery

| Backup Type | Frequency | Retention | Last Verified |
|-------------|-----------|-----------|---------------|
| Database | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Application Code | Git repository | Indefinite | [PLACEHOLDER] |
| Configuration | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Full Server Snapshot | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

### Monitoring & Alerting

| Monitor | Tool | Alert Channel | Threshold |
|---------|------|---------------|-----------|
| Uptime | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Response Time | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Error Rate | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Disk Usage | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Memory Usage | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| SSL Expiry | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

### Deployment Procedures

| Stage | Process | Approval Required | Rollback Time |
|-------|---------|-------------------|---------------|
| Development | [PLACEHOLDER] | No | N/A |
| Staging | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Production | [PLACEHOLDER] | [PLACEHOLDER - Yes/No] | [PLACEHOLDER] |

### Incident Response

| Severity | Response Time | Escalation Path | Communication Channel |
|----------|---------------|-----------------|------------------------|
| P1 (Critical) | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| P2 (High) | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| P3 (Medium) | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| P4 (Low) | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

### Change Management

| Change Type | Approval Process | Testing Required | Rollback Plan |
|-------------|------------------|------------------|---------------|
| Code Deployment | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Configuration Change | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Infrastructure Change | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
| Emergency Fix | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

## Other Critical Sites

### [PLACEHOLDER - Site 2]

| Attribute | Value |
|-----------|-------|
| **Domain** | [PLACEHOLDER] |
| **Criticality Level** | [PLACEHOLDER] |
| **Business Function** | [PLACEHOLDER] |
| **Revenue Impact** | [PLACEHOLDER] |
| **User Impact** | [PLACEHOLDER] |
| **Uptime Requirement** | [PLACEHOLDER] |

[Add additional critical sites as needed]

## Documentation History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| [PLACEHOLDER] | 1.0 | Initial creation | [PLACEHOLDER] |

## Next Review

- **Review Date:** [PLACEHOLDER]
- **Review Cycle:** [PLACEHOLDER - Monthly/Quarterly]
- **Reviewer:** [PLACEHOLDER]

---

**Note:** This document contains operational details. Handle according to information security policies. Do not share externally without explicit approval.