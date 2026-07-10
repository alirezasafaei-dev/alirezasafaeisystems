# ASDEV AUTOMATION SERVER REBOOT DRILL RUNBOOK

## Status: PREPARED_NOT_EXECUTED

**Date prepared**: 2026-07-10
**Server**: asdev@91.107.153.223 (asdevserve)
**Repository**: /home/asdev/repos/alirezasafaeisystems
**Branch**: main
**HEAD**: (captured at drill time)

## Pre-reboot baseline

Before executing the reboot drill, capture and record:

```bash
# Capture baseline
echo "=== PRE-REBOOT BASELINE ===" > /tmp/reboot-drill-baseline.txt
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /tmp/reboot-drill-baseline.txt
echo "Hostname: $(hostname -f)" >> /tmp/reboot-drill-baseline.txt
echo "Branch: $(git -C /home/asdev/repos/alirezasafaeisystems branch --show-current)" >> /tmp/reboot-drill-baseline.txt
echo "HEAD: $(git -C /home/asdev/repos/alirezasafaeisystems rev-parse HEAD)" >> /tmp/reboot-drill-baseline.txt
echo "Origin: $(git -C /home/asdev/repos/alirezasafaeisystems rev-parse origin/main)" >> /tmp/reboot-drill-baseline.txt
echo "Dirty: $(git -C /home/asdev/repos/alirezasafaeisystems status --short | wc -l)" >> /tmp/reboot-drill-baseline.txt
systemctl --user list-timers --all --no-pager >> /tmp/reboot-drill-baseline.txt
systemctl --user list-units --all 'asdev-*' --no-pager >> /tmp/reboot-drill-baseline.txt
loginctl show-user asdev -p Linger >> /tmp/reboot-drill-baseline.txt
cat /home/asdev/repos/alirezasafaeisystems/.state/asdev-supervisor/latest.json >> /tmp/reboot-drill-baseline.txt
cat /home/asdev/repos/alirezasafaeisystems/.state/asdev-mcp/latest.json >> /tmp/reboot-drill-baseline.txt
echo "=== BASELINE CAPTURED ==="
```

## Backup/recovery branch verification

```bash
# Verify recovery branches exist
git -C /home/asdev/repos/alirezasafaeisystems branch --list 'recovery/*'
# Verify no uncommitted changes
git -C /home/asdev/repos/alirezasafaeisystems status --short
# If dirty, commit or stash first
```

## Connectivity expectations

- SSH to server: `ssh asdev@91.107.153.223`
- Expected downtime: 1-3 minutes
- Server should come back within 60 seconds of reboot command

## Exact reboot command

```bash
# ONLY execute after exact approval phrase:
# APPROVE_AUTOMATION_SERVER_REBOOT_DRILL
sudo reboot
```

## Post-reboot SSH retry strategy

```bash
# Wait 60 seconds, then attempt SSH
for i in $(seq 1 10); do
  sleep 10
  if ssh -o ConnectTimeout=5 asdev@91.107.153.223 "echo REBOOT_OK" 2>/dev/null; then
    echo "SSH restored after $((i * 10)) seconds"
    break
  fi
  echo "Attempt $i: not ready yet..."
done
```

## Post-reboot verification checklist

### 1. Systemd linger verification
```bash
loginctl show-user asdev -p Linger
# Expected: Linger=yes
```

### 2. Timer/service verification
```bash
systemctl --user list-timers --all --no-pager
systemctl --user list-units --all 'asdev-*' --no-pager
# Expected: all 5 timers active, asdev-bot running
```

### 3. Git branch/cleanliness verification
```bash
cd /home/asdev/repos/alirezasafaeisystems
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git status --short
# Expected: branch=main, HEAD matches baseline, no unknown dirty files
```

### 4. MCP verification
```bash
bash scripts/control-plane/mcp-health-check-v2.sh
# Expected: verdict=PASS
cat .state/asdev-mcp/latest.json
```

### 5. Hermes (bot) verification
```bash
systemctl --user status asdev-bot.service --no-pager
# Expected: active (running)
```

### 6. GitHub sync verification
```bash
bash scripts/control-plane/sync-github-local-server.sh
# Expected: status=ok
cat docs/reports/automation-server/latest-github-sync.md
```

### 7. Supervisor verification
```bash
bash scripts/control-plane/asdev-supervisor.sh
# Expected: verdict=GO
cat .state/asdev-supervisor/latest.json
```

### 8. No restart-loop verification
```bash
# Check that services aren't flapping
sleep 60
systemctl --user list-units --all 'asdev-*' --no-pager
# Check journal for restart loops
journalctl --user -u asdev-supervisor.service --since "5 minutes ago" --no-pager | tail -20
```

### 9. AI Gateway remains disabled
```bash
# Verify AI Gateway automation is NOT enabled
grep -r "APPROVE_AI_GATEWAY" /home/asdev/repos/alirezasafaeisystems/.state/ 2>/dev/null || echo "AI Gateway not enabled"
```

## Rollback/recovery steps

If the server does not recover after reboot:

1. **SSH fails after 5 minutes**: Check Hetnzer console for server status
2. **Systemd timers not starting**: Verify linger with `loginctl enable-linger asdev`
3. **Git repo corrupted**: Restore from recovery branch
4. **Services failing**: Check logs with `journalctl --user -u <service> --no-pager`
5. **Complete failure**: Contact owner for manual intervention

## Final status

After successful verification, record:

```
REBOOT_DRILL_EXECUTED_SUCCESSFULLY
Timestamp: <UTC>
Pre-reboot HEAD: <sha>
Post-reboot HEAD: <sha>
All timers active: yes/no
All services: <status>
MCP verdict: <verdict>
Supervisor verdict: <verdict>
```

If drill is NOT executed:

```
REBOOT_DRILL_PREPARED_NOT_EXECUTED
```
