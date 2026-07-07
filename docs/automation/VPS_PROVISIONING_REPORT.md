# VPS Provisioning Report — Continued

**Status:** Partially complete — GitHub auth pending
**Date:** 2026-07-07

## Completed

| Step | Status |
|---|---|
| SSH key login | ✅ Works |
| Base packages | ✅ Installed |
| Firewall (UFW) | ✅ Configured (sudo-limited) |
| Fail2ban | ✅ Installed (sudo-limited) |
| Timezone | ✅ UTC |
| Node.js v22.16.0 | ✅ Installed (user dir) |
| npm 10.9.2 | ✅ Installed |
| pnpm 11.10.0 | ✅ Installed |
| gh CLI 2.96.0 | ✅ Installed |

## Pending

| Step | Status | Action Needed |
|---|---|---|
| GitHub auth | ⏳ | Owner must run `gh auth login` on VPS |
| Repo clone | ⏳ | After gh auth |
| Deps install | ⏳ | After repo clone |
| Systemd timer | ⏳ | After deps |
| Healthcheck | ⏳ | After timer |
| Dry-run | ⏳ | After healthcheck |

## Manual Steps for Owner

### 1. Set up sudo (optional but recommended)

On VPS console:

```bash
echo 'asdev ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/asdev
```

### 2. Authenticate GitHub CLI

On VPS:

```bash
export PATH=$HOME/node/bin:$PATH
gh auth login
```

Choose:
- GitHub.com
- HTTPS
- Paste an authentication token

### 3. Clone repos after auth

```bash
cd ~/repos
git clone git@github.com:alirezasafaei-dev/alirezasafaeisystems.git
git clone git@github.com:alirezasafaei-dev/auditsystems.git
```

### 4. Install dependencies

```bash
export PATH=$HOME/node/bin:$PATH
cd ~/repos/alirezasafaeisystems && pnpm install
cd ~/repos/auditsystems && NODE_OPTIONS="--max-old-space-size=2048" pnpm install
```

### 5. Set up systemd timer

```bash
mkdir -p ~/.config/systemd/user
cp ~/repos/alirezasafaeisystems/ops/systemd/vps/asdev-agent-loop.service ~/.config/systemd/user/
cp ~/repos/alirezasafaeisystems/ops/systemd/vps/asdev-agent-loop.timer ~/.config/systemd/user/
systemctl --user daemon-reload
sudo loginctl enable-linger asdev
systemctl --user enable --now asdev-agent-loop.timer
```

### 6. Run healthcheck

```bash
cd ~/repos/alirezasafaeisystems
./scripts/agent-command-center/agent-healthcheck.sh
```

## SSH Hardening Status

SSH config hardened:
- PasswordAuthentication no
- PubkeyAuthentication yes
- PermitRootLogin no
- AllowUsers asdev

## VPS Specs

| Resource | Value |
|---|---|
| OS | Ubuntu 24.04 LTS |
| CPU | 2 vCPU |
| RAM | 3.7GB |
| Disk | 38GB (34GB free) |
| Location | Germany |
| Node.js | v22.16.0 |
| pnpm | 11.10.0 |
| gh CLI | 2.96.0 |
