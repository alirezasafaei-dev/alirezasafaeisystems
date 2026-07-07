# VPS Cutover Plan

**Status:** Ready
**Date:** 2026-07-07

## Cutover Rules

1. Keep local timer active until VPS healthcheck passes
2. Install VPS timer but start in dry-run first
3. Run VPS safe real job once
4. Confirm Issue #45 report from VPS
5. Stop local timer
6. Enable VPS recurring timer
7. Keep local machine as fallback for 48 hours

## Step-by-Step

### Phase 1: VPS Validation (No Local Changes)

```bash
# On VPS
./scripts/agent-command-center/agent-healthcheck.sh
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1 --dry-run
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1
# Confirm report on Issue #45
```

### Phase 2: Stop Local Timer

```bash
# On local machine
systemctl --user stop asdev-agent-loop.timer
systemctl --user disable asdev-agent-loop.timer
# Verify
systemctl --user status asdev-agent-loop.timer
```

### Phase 3: Enable VPS Timer

```bash
# On VPS
systemctl --user enable --now asdev-agent-loop.timer
# Verify
systemctl --user status asdev-agent-loop.timer
systemctl --user list-timers | grep asdev
```

### Phase 4: Monitor (48 hours)

```bash
# Check VPS daily
ssh asdev@vps-ip
./scripts/agent-command-center/agent-healthcheck.sh
journalctl --user -u asdev-agent-loop.service -n 50 --no-pager
```

## Emergency Rollback

If VPS fails:

```bash
# On VPS — stop
systemctl --user stop asdev-agent-loop.timer

# On local machine — restart
systemctl --user enable --now asdev-agent-loop.timer
```

## Duplicate Execution Prevention

- Cutover is sequential: stop local → enable VPS
- Never run both timers simultaneously for production
- Local machine stays as cold standby for 48 hours
- After 48 hours, local timer can be permanently disabled
