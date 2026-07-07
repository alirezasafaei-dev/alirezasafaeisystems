# Cloud Runner Options — ASDEV Automation

**Date:** 2026-07-07

## Comparison

| Platform | Agent Runner | Cron | Filesystem | systemctl | Verdict |
|---|---|---|---|---|---|
| **VPS** | ✅ Full | ✅ systemd | ✅ Persistent | ✅ Yes | **Best for full runner** |
| **GitHub Actions** | ⚠️ 6hr limit | ✅ cron schedule | ❌ Ephemeral | ❌ No | Good fallback scheduler |
| **Cloudflare Workers** | ❌ Stateless | ⚠️ Cron triggers | ❌ KV only | ❌ No | Heartbeat/trigger only |
| **Vercel Cron** | ❌ Serverless | ⚠️ Cron only | ❌ Ephemeral | ❌ No | Trigger only |
| **HuggingFace Spaces** | ⚠️ Sleeps | ❌ No | ⚠️ Persistent | ❌ No | Unreliable daemon |
| **Render Free** | ⚠️ Sleeps | ❌ No | ⚠️ Ephemeral | ❌ No | Not ideal |

## Recommendation

**Primary:** VPS (Ubuntu 24.04)
- Full control
- Persistent filesystem
- systemd timers
- No sleep/spin-down
- SSH access

**Fallback:** GitHub Actions
- Cron schedule can trigger builds
- Free tier available
- Good for heartbeat checks

**Not recommended as primary:**
- Cloudflare Workers (stateless)
- Vercel Cron (trigger only)
- HuggingFace (sleeps)
- Render (ephemeral)
