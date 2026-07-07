# Autonomous Service Reliability

**Status:** Active
**Date:** 2026-07-07

## Why User Lingering Matters

systemd user timers only run while the user session is active. Without lingering, timers die on logout/reboot. With lingering, systemd manages user timers even when no session exists.

## Enable Linger

```bash
loginctl enable-linger "$USER"
loginctl show-user "$USER" -p Linger
# Expected: Linger=yes
```

## Verify After Reboot

```bash
loginctl show-user "$USER" -p Linger
systemctl --user status asdev-agent-loop.timer
systemctl --user list-timers | grep asdev
journalctl --user -u asdev-agent-loop.service -n 20 --no-pager
```

## Disable Linger

```bash
loginctl disable-linger "$USER"
systemctl --user stop asdev-agent-loop.timer
systemctl --user disable asdev-agent-loop.timer
```

## Timer Behavior

| Setting | Value |
|---|---|
| OnBootSec | 5min after boot |
| OnUnitActiveSec | 30min after last run |
| Persistent | Catch up missed runs |
| RandomizedDelay | Up to 2min jitter |

## Recovery Checklist

1. Check linger: `loginctl show-user "$USER" -p Linger`
2. Check timer: `systemctl --user status asdev-agent-loop.timer`
3. Check last run: `journalctl --user -u asdev-agent-loop.service -n 20`
4. Run healthcheck: `./scripts/agent-command-center/agent-healthcheck.sh`
5. If timer not active: `systemctl --user enable --now asdev-agent-loop.timer`
6. If linger not set: `loginctl enable-linger "$USER"`

## Network Recovery

The loop checks network before processing tasks. If network is unavailable:
- No tasks are consumed
- Service exits 0 (not failure)
- Next cycle retries normally

## Circuit Breaker

| Consecutive Failures | Action |
|---|---|
| 3 | Pause product-branch tasks, run read-only/docs-only only |
| 5 | Stop loop, require owner review |

## Emergency Stop

```bash
systemctl --user stop asdev-agent-loop.timer
systemctl --user disable asdev-agent-loop.timer
```
