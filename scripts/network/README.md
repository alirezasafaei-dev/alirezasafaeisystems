# Network Diagnostics & Split Proxy

## 1) Diagnose edge/CDN route failures (504 / x-sid 6980)

Run from local workstation:

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/diagnose-edge-route.sh
```

What it checks:
- `default` path (current proxy/vpn environment)
- `--noproxy '*'` direct path
- Nginx origin access log hit via SSH (`deploy@185.3.124.93`)

Report output:
- `reports/edge-route/<UTC>-edge-route.md`

Interpretation:
- `default=504` + `noproxy!=504` + origin hit = failure before origin (CDN/edge route issue)
- both `504` = origin/app side issue

## 2) Chrome split-proxy launcher (local)

Use when OpenAI must stay on proxy but your own domains should open directly:

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/chrome-split-proxy.sh
```

Optional proxy override:

```bash
PROXY_SERVER="socks5://127.0.0.1:10808" ./scripts/network/chrome-split-proxy.sh
```

## 3) CDN panel actions (for permanent end-user fix)

In CDN panel (Arvan), apply:
1. Validate origin protocol/port from all POPs (not only Iran route).
2. Ensure no country/ASN block is active for edge-to-origin path.
3. Create direct non-CDN fallback host (DNS-only) for emergency/GSC checks.
4. Open support ticket with report file and run id.

## 4) Apply local NO_PROXY policy (recommended)

Keeps OpenAI traffic on proxy while forcing your own domains to go direct for CLI/tools:

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/apply-local-proxy-policy.sh
```

This updates:
- `~/.config/asdev/proxy-policy.env`
- `~/.zshrc`
- `~/.bashrc`

## 5) Install VPS health watch (every 5 minutes)

Installs a root cron job on VPS:
- checks origin endpoints (`127.0.0.1` ports)
- checks edge endpoints (public domains)
- appends logs to `/var/log/asdev-health-watch.log`

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/install-vps-health-watch.sh
```

### Optional: Telegram alerts for failures

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
TELEGRAM_BOT_TOKEN="xxx" TELEGRAM_CHAT_ID="yyy" ./scripts/network/configure-vps-telegram-alert.sh
```

Settings file on VPS:
- `/etc/default/asdev-health-watch`

Log rotation:
- `/etc/logrotate.d/asdev-health-watch`

## 6) Weekly SLO report (automatic)

Installs a weekly cron (Sunday 23:55 server time) and generates markdown reports:

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/install-vps-weekly-slo-report.sh
```

Outputs on VPS:
- `/var/log/asdev-health-weekly-<timestamp>.md`
- `/var/log/asdev-health-weekly-latest.md`

## 7) One-command monitoring bootstrap

Use this to set/update the full monitoring suite:

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/bootstrap-monitoring-suite.sh
```

## 8) One-command network+SEO ops run (local)

Runs:
1. Edge route diagnosis
2. GSC preflight
3. Chromium network smoke matrix

```bash
cd /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems
./scripts/network/run-network-seo-ops.sh
```
