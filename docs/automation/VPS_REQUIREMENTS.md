# VPS Requirements — ASDEV Autonomous Agent

**Status:** Ready for procurement
**Date:** 2026-07-07

## Recommended Specs

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4GB | 8GB |
| Disk | 40GB SSD | 80GB NVMe |
| OS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| IPv4 | 1 public | 1 public |

## Location

**Recommended:** Germany, Netherlands, or France.

**Why:**
- Low latency to GitHub API
- Good connectivity to Iranian developers
- GDPR-compliant data handling
- Stable hosting providers available
- Not subject to Iran-specific sanctions

**Why not Iran VPS:**
- GitHub API latency can be high
- Provider reliability varies
- Snapshots/backups less reliable
- Network interruptions more frequent

**Why not Cloudflare/Vercel as primary agent host:**
- Workers/Functions are stateless — cannot run persistent daemon
- Cron triggers only, not full agent execution
- No filesystem access for repos
- No systemctl for systemd timers

## Sizing by Use Case

### Light Automation (current)
- Autonomous loop only
- 2 jobs per 30min cycle
- 2 vCPU / 4GB RAM / 40GB disk

### Automation + Telegram Bot
- Long-polling bot + loop
- 2 vCPU / 4GB RAM / 40GB disk

### Automation + Docker/n8n
- Container-based workflows
- 4 vCPU / 8GB RAM / 80GB disk

## Network Requirements

- Outbound HTTPS (443) to github.com, api.github.com
- Outbound SSH (22) for git push (optional — can use HTTPS)
- Inbound SSH (22) for admin access
- Optional: ports 80/443 for Telegram webhook later

## Backup Requirements

- Weekly snapshots (provider-level)
- Daily `/opt/asdev` backup via rsync
- Git repos are self-backing (GitHub)
- State file backed up with agent directory

## SSH Key Requirement

- Ed25519 or RSA 4096
- Added to VPS during provisioning
- Password login disabled after key confirmed working

## Disk Usage Estimate

| Component | Space |
|---|---|
| Node.js + pnpm | ~500MB |
| 3 repos (cloned) | ~2GB |
| node_modules (auditsystems) | ~1GB |
| Logs (30 days) | ~200MB |
| System + packages | ~2GB |
| **Total** | **~6GB** |

80GB NVMe provides ample headroom.
