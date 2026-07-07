# VPS Cutover Status

**Date:** 2026-07-07
**Status:** Blocked — VPS not yet provisioned

## Current State

| Component | Status |
|---|---|
| VPS purchased | ✅ |
| VPS accessible | ❌ (password expired) |
| Manual password change | ⏳ Owner must do via provider console |
| SSH key setup | ⏳ After manual setup |
| Base hardening | ⏳ After SSH access |
| Runtime install | ⏳ After base hardening |
| Repo clone | ⏳ After runtime |
| Systemd timer | ⏳ After repos |
| Healthcheck | ⏳ After timer |
| Dry-run | ⏳ After healthcheck |
| Cutover | ⏳ After dry-run |

## Local Timer Status

- Local timer: active (fallback)
- VPS timer: not installed (blocked)
- Cutover: not started

## Cutover Sequence

1. Owner changes password via provider console
2. Owner creates asdev user and sets SSH key
3. Agent runs bootstrap script
4. Agent installs systemd timer
5. Agent runs healthcheck
6. Agent runs dry-run
7. Agent runs one safe real job
8. Local timer stopped
9. VPS becomes main controller

## Emergency Rollback

```bash
# On VPS
systemctl --user stop asdev-agent-loop.timer

# On local machine
systemctl --user enable --now asdev-agent-loop.timer
```
