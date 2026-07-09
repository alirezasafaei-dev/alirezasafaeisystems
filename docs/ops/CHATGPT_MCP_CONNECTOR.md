# ChatGPT MCP Connector — ASDEV GitHub Assistant

## Overview

This document describes how to deploy, configure, and connect the
**ASDEV ChatGPT MCP Server** — a read-only MCP (Model Context Protocol) server
that lets ChatGPT inspect ASDEV GitHub repositories.

## Status

| Service | URL | Status |
|---------|-----|--------|
| MCP Server (systemd) | `http://127.0.0.1:8000` | ✅ active |
| Caddy Reverse Proxy (systemd) | `https://mcp.alirezasafaeisystems.ir` | ✅ active |
| TLS | Let's Encrypt (auto via Caddy) | ✅ valid |
| UFW Firewall | ports 80/tcp, 443/tcp | ✅ open |

## Quick links

| Item | Location |
|------|----------|
| Source code | `tools/asdev-chatgpt-mcp/` |
| Systemd unit | `deploy/systemd/asdev-chatgpt-mcp.service.example` |
| Nginx config | `deploy/nginx/asdev-chatgpt-mcp.conf.example` |
| Caddy config | `deploy/caddy/asdev-chatgpt-mcp.Caddyfile.example` |
| Deployment docs | This file |

## Server deployment

### Prerequisites

- Python ≥ 3.10
- A GitHub personal access token with `repo` scope (for private repos) or
  `public_repo` scope (for public repos only).
- DNS record: `mcp.alirezasafaeisystems.ir` → `91.107.153.223`

### Step-by-step

```bash
# 1. Clone the repository (if not already present)
cd /home/asdev/apps
git clone git@github.com:alirezasafaei-dev/alirezasafaeisystems.git
cd alirezasafaeisystems

# 2. Create virtualenv and install deps
cd tools/asdev-chatgpt-mcp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# Edit .env → set GITHUB_TOKEN

# 4. Test the server
python server.py
# The server listens on http://127.0.0.1:8000
```

### Firewall (UFW)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### systemd service — MCP server

```bash
# Install the systemd unit
sudo cp deploy/systemd/asdev-chatgpt-mcp.service.example \
      /etc/systemd/system/asdev-chatgpt-mcp.service

# Edit the service file to match your environment if needed

sudo systemctl daemon-reload
sudo systemctl enable --now asdev-chatgpt-mcp
sudo systemctl status asdev-chatgpt-mcp --no-pager
```

### Reverse proxy

#### Nginx

```bash
sudo cp deploy/nginx/asdev-chatgpt-mcp.conf.example \
      /etc/nginx/sites-available/mcp.alirezasafaeisystems.ir
sudo ln -s /etc/nginx/sites-available/mcp.alirezasafaeisystems.ir \
           /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### Caddy (production — used on asdevserve)

> **Important**: The MCP library v1+ enables DNS rebinding protection by default
> when `host` is `127.0.0.1`. Caddy must forward the Host header as the upstream
> hostport (`127.0.0.1:8000`) or the library rejects requests with `421
> Misdirected Request`.

Production Caddyfile used on the server (`/home/asdev/apps/mcp-server/Caddyfile.prod`):

```caddy
mcp.alirezasafaeisystems.ir {
	reverse_proxy /sse* 127.0.0.1:8000 {
		header_up Host {upstream_hostport}
		flush_interval 0
	}
	reverse_proxy /messages* 127.0.0.1:8000 {
		header_up Host {upstream_hostport}
	}
}
```

Caddy will auto-provision TLS via Let's Encrypt. No `tls internal` — that
forces a self-signed cert and breaks public access.

### Enable HTTPS (Nginx only)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d mcp.alirezasafaeisystems.ir
```

Caddy handles TLS automatically.

## ChatGPT connector configuration

Fill in these values in the **ChatGPT MCP connector** setup page:

| Field | Value |
|-------|-------|
| **Name** | ASDEV GitHub Assistant |
| **Description** | Helps analyze ASDEV GitHub repositories, project files, issues, pull requests, commits, and development workflows. |
| **Connection** | Server URL |
| **Authentication** | None for private testing; OAuth later for production/team use |
| **Server URL** | `https://mcp.alirezasafaeisystems.ir/sse/` |

## Testing the endpoint

### SSE handshake

```bash
# Local (from the server)
curl -N http://127.0.0.1:8000/sse

# Public
curl -N https://mcp.alirezasafaeisystems.ir/sse
```

A successful response shows:

```
event: endpoint
data: /messages/?session_id=<uuid>
```

### Full MCP protocol verification

Use Python to verify the full round-trip (initialize → tools/list → tools/call):

```python
import json, urllib.request, threading, time

BASE = "https://mcp.alirezasafaeisystems.ir"
sse_events = []
stop = threading.Event()

def read_sse():
    r = urllib.request.urlopen(f"{BASE}/sse", timeout=15)
    while not stop.is_set():
        try:
            chunk = r.read1(4096)
            if not chunk: break
            for line in chunk.decode().split("\n"):
                if line.startswith("data: "):
                    sse_events.append(line[6:].strip())
        except: break

t = threading.Thread(target=read_sse, daemon=True)
t.start()
time.sleep(2)

# Extract session URL
msg = next(ev for ev in sse_events if ev.startswith("/messages/"))
session_url = BASE + msg

def post(data):
    req = urllib.request.Request(session_url,
        data=json.dumps(data).encode(),
        headers={"Content-Type":"application/json"}, method="POST")
    return urllib.request.urlopen(req, timeout=10)

# 1. Initialize
post({"jsonrpc":"2.0","id":1,"method":"initialize",
      "params":{"protocolVersion":"2024-11-05","capabilities":{},
                "clientInfo":{"name":"test","version":"1.0"}}})
time.sleep(1)
# 2. Notify initialized
post({"jsonrpc":"2.0","method":"notifications/initialized"})
time.sleep(1)
# 3. List tools
post({"jsonrpc":"2.0","id":2,"method":"tools/list"})
time.sleep(2)
# 4. Call a tool
post({"jsonrpc":"2.0","id":3,"method":"tools/call",
      "params":{"name":"list_repositories","arguments":{"limit":2}}})
time.sleep(3)

for ev in sse_events:
    try:
        print(json.dumps(json.loads(ev), indent=2)[:500])
    except:
        print(f"(raw) {ev[:80]}")

stop.set()
t.join(timeout=2)
```

### Expected tool list

| Tool | Description |
|------|-------------|
| `list_repositories` | List repos under the configured GitHub owner |
| `get_repository_summary` | Get detailed summary of a specific repo |
| `search_code` | Search code across repos |
| `read_file` | Read a file from a repo |
| `list_issues` | List issues for a repo |
| `list_pull_requests` | List PRs for a repo |

## Security considerations

| Concern | Mitigation |
|---------|------------|
| Token exposure | Read from `GITHUB_TOKEN` env var only. Never logged. |
| Unauthorised repo access | Scoped to `GITHUB_OWNER`; further restricted by `ALLOWED_REPOS`. |
| Path traversal | Rejected by `read_file` tool. |
| Large file reads | Capped at `MAX_FILE_BYTES` (default 1 MiB). |
| Network exposure | Binds to `127.0.0.1`; only accessible via reverse proxy. |
| Write operations | **None exposed.** All tools are read-only. |
| TLS | Terminated at reverse proxy. |

## Production troubleshooting

### "Invalid Host header" / 421 Misdirected Request

The MCP library v1+ enables DNS rebinding protection when binding to `127.0.0.1`.
It only accepts `Host` headers matching `127.0.0.1:*`, `localhost:*`, or `[::1]:*`.

**Fix**: In Caddy (or any reverse proxy), override the forwarded Host header:

```caddy
reverse_proxy /sse* 127.0.0.1:8000 {
    header_up Host {upstream_hostport}
}
```

### Let's Encrypt certificate not obtained

Remove `tls internal` from the Caddyfile. Ensure UFW/firewall allows ports
80 and 443. Then restart Caddy:

```bash
sudo systemctl restart asdev-chatgpt-caddy
journalctl -u asdev-chatgpt-caddy -f  # watch for "certificate obtained successfully"
```

## Next hardening steps

1. Add rate-limiting at the reverse-proxy level (Caddy `rate_limit` directive).
2. Switch to a fine-grained GitHub token with minimal permissions.
3. Add OAuth authentication for the ChatGPT connector.
4. Monitor via systemd journal (`journalctl -u asdev-chatgpt-mcp -f`).
5. Set up log rotation for the MCP server logs.
6. Install `libnss3-tools` on the server to let Caddy install its root CA locally.
