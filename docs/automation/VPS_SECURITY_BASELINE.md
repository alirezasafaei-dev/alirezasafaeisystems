# VPS Security Baseline

**Date:** 2026-07-07
**Status:** Pending manual password change

## Required Hardening (After Manual Setup)

### SSH Hardening

Create `/etc/ssh/sshd_config.d/99-asdev-hardening.conf`:

```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
KbdInteractiveAuthentication no
X11Forwarding no
AllowUsers asdev
ClientAliveInterval 300
ClientAliveCountMax 2
```

Then:

```bash
sudo sshd -t && sudo systemctl restart ssh
```

### Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw --force enable
```

### Fail2ban

```bash
sudo apt-get install -y fail2ban
sudo systemctl enable --now fail2ban
```

### Unattended Upgrades

```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -f noninteractive unattended-upgrades
```

### Timezone

```bash
sudo timedatectl set-timezone UTC
```

## Verification

```bash
# SSH config valid
sudo sshd -t

# UFW active
sudo ufw status verbose

# Fail2ban active
sudo systemctl status fail2ban

# Key-only login works
ssh -i ~/.ssh/asdev_vps_ed25519 asdev@VPS_HOST "whoami"
```
