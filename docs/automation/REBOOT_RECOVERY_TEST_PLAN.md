# Reboot Recovery Test Plan

**Status:** Ready to execute
**Date:** 2026-07-07

## Pre-Reboot Checklist

```bash
# 1. Verify linger is enabled
loginctl show-user "$USER" -p Linger
# Expected: Linger=yes

# 2. Verify timer is active
systemctl --user status asdev-agent-loop.timer
# Expected: Active: active (waiting)

# 3. Run healthcheck
./scripts/agent-command-center/agent-healthcheck.sh
# Expected: All checks passed

# 4. Note current timer state
systemctl --user list-timers | grep asdev
```

## Reboot Command (Owner Must Run)

```bash
sudo reboot
# or
sudo shutdown -r now
```

## Post-Reboot Checks

```bash
# 1. Check linger survived
loginctl show-user "$USER" -p Linger
# Expected: Linger=yes

# 2. Check timer is active
systemctl --user status asdev-agent-loop.timer
# Expected: Active: active (waiting)

# 3. Check next trigger
systemctl --user list-timers | grep asdev
# Expected: next trigger in ~30min

# 4. Check service logs
journalctl --user -u asdev-agent-loop.service -n 20 --no-pager
# Expected: recent run or "no entries" if first trigger hasn't fired

# 5. Run healthcheck
./scripts/agent-command-center/agent-healthcheck.sh
# Expected: All checks passed
```

## Recovery if Timer Not Active

```bash
# Re-enable timer
systemctl --user enable --now asdev-agent-loop.timer

# If still not working, check linger
loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now asdev-agent-loop.timer
```

## Network-Offline Test

```bash
# Simulate offline
sudo iptables -A OUTPUT -d github.com -j DROP

# Run loop — should skip tasks gracefully
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1 --simulate-offline
# Expected: exits 0, no tasks consumed

# Restore network
sudo iptables -D OUTPUT -d github.com -j DROP
```

## Network-Reconnect Test

```bash
# After offline test, verify loop works normally
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1 --dry-run
# Expected: processes queue normally
```

## Emergency Stop

```bash
# Stop timer
systemctl --user stop asdev-agent-loop.timer

# Disable timer
systemctl --user disable asdev-agent-loop.timer

# Verify stopped
systemctl --user status asdev-agent-loop.timer
# Expected: Active: inactive (dead)
```

## Expected Logs After Reboot

```
Jul XX XX:XX:XX hostname systemd[XXXX]: Started ASDEV Autonomous Agent Loop Timer.
Jul XX XX:XX:XX hostname systemd[XXXX]: Starting ASDEV Autonomous Agent Loop...
Jul XX XX:XX:XX hostname run-autonomous-loop.sh[XXXX]: [XX:XX:XX] Timestamp: ...
Jul XX XX:XX:XX hostname run-autonomous-loop.sh[XXXX]: [XX:XX:XX] Pending tasks: ...
Jul XX XX:XX:XX hostname run-autonomous-loop.sh[XXXX]: [XX:XX:XX] Loop completed successfully
```
