# VPS Provisioning Report

**Status:** Blocked — password expired
**Date:** 2026-07-07
**VPS:** Ubuntu 24.04, 2 vCPU, 4GB RAM, 40GB disk, Germany

## Current Status

The VPS has an expired root password that requires interactive TTY for changing. All non-interactive SSH connections are blocked.

## What Was Attempted

1. SSH connection with password — blocked (password expired)
2. SSH connection with existing keys — blocked (too many auth failures)
3. Password change via SSH — blocked (requires TTY)
4. Sudo password change — blocked (requires TTY)

## Root Cause

The VPS provider sets an initial password with forced expiry. This requires:
- Interactive console access (web-based VPS console)
- Or provider API to reset password
- Or rescue mode to change password

## Resolution Steps

The owner must:

1. Log into VPS provider console (web interface)
2. Open VPS console/terminal
3. Login with current credentials
4. Change root password when prompted
5. Create `asdev` user: `useradd -m -s /bin/bash asdev`
6. Set password for asdev: `passwd asdev`
7. Add SSH key: `mkdir -p /home/asdev/.ssh && echo "PUBKEY" > /home/asdev/.ssh/authorized_keys`
8. Set permissions: `chmod 700 /home/asdev/.ssh && chmod 600 /home/asdev/.ssh/authorized_keys && chown -R asdev:asdev /home/asdev/.ssh`

## After Manual Setup

Once the owner completes manual setup, run:

```bash
# Generate SSH key locally (if not done)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/asdev_vps_ed25519 -C "asdev-vps-controller" -N ""

# Test connection
ssh -i ~/.ssh/asdev_vps_ed25519 asdev@VPS_HOST "whoami"

# Run bootstrap
ssh -i ~/.ssh/asdev_vps_ed25519 asdev@VPS_HOST "bash -s" < scripts/vps/bootstrap-asdev-agent.sh
```

## Security Notes

- VPS IP: [REDACTED]
- Password changed by owner via console
- SSH key login preferred after initial setup
- Password login will be disabled after key verified
