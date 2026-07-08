# IRAN_PROD Site Inventory (Redacted)

**Document Version:** 1.0
**Last Updated:** 2026-07-08
**Classification:** INTERNAL - PRODUCTION OPERATIONS

---

## Overview

This document provides a redacted inventory of IRAN_PROD production server. All sensitive information (IPs, secrets, credentials) has been removed. Use `scripts/ops/iran-prod-inventory.sh` to generate a fresh inventory.

---

## Server Information

| Attribute | Value |
|-----------|-------|
| **Hostname** | [REDACTED] |
| **Kernel** | Linux |
| **CPU Count** | [Run inventory to collect] |
| **Memory Total** | [Run inventory to collect] |
| **Swap Total** | [Run inventory to collect] |

---

## Deployed Sites

### Site: auditsystems

| Attribute | Value |
|-----------|-------|
| **Domain** | auditsystems.ir |
| **Criticality** | Normal |
| **Deploy Path** | /srv/asdev/sites/auditsystems/ |
| **Status** | Active |

### Site: alirezasafaeisystems

| Attribute | Value |
|-----------|-------|
| **Domain** | alirezasafaeisystems.ir |
| **Criticality** | Normal |
| **Deploy Path** | /srv/asdev/sites/alirezasafaeisystems/ |
| **Status** | Active |

### Site: persiantoolbox

| Attribute | Value |
|-----------|-------|
| **Domain** | persiantoolbox.ir |
| **Criticality** | CRITICAL |
| **Deploy Path** | /srv/asdev/sites/persiantoolbox/ |
| **Status** | Active |

---

## Infrastructure Components

### Web Server
- **Type:** Nginx
- **Config Location:** /etc/nginx/sites-available/
- **Status:** Active

### Process Manager
- **Type:** PM2
- **Processes:** [Run inventory to list]

### Database
- **Type:** [Run inventory to identify]
- **Status:** [Run inventory to check]

---

## Disk Usage Summary

| Mount | Total | Used | Available | Use% |
|-------|-------|------|-----------|------|
| / | [REDACTED] | [REDACTED] | [REDACTED] | [REDACTED] |

---

## Port Usage

| Port | Protocol | Process |
|------|----------|---------|
| [Run inventory to collect] | | |

---

## SSL Certificates

| Domain | Expiry | Auto-Renewal |
|--------|--------|--------------|
| [Run inventory to collect] | | |

---

## How to Refresh This Inventory

```bash
# Run the inventory script (requires approval)
./scripts/ops/iran-prod-inventory.sh APPROVE_IRAN_PROD_SITE_INVENTORY
```

**Note:** The inventory script automatically redacts IPs and secrets before output.

---

**Classification:** This document contains operational details. Handle according to information security policies. Do not share externally without explicit approval.
