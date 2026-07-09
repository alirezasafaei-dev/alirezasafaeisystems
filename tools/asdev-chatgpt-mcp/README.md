# ASDEV ChatGPT MCP Server

Read-only MCP server scaffold for connecting ChatGPT Developer Mode to the ASDEV GitHub workspace.

This belongs in the ASDEV mother repository because this repository is the canonical parent brand, governance, and agent-rules source for ASDEV.

## Target server

Deploy this service directly on the automation server without Docker:

```text
SSH: asdev@91.107.153.223
Domain: mcp.alirezasafaeisystems.ir
Public endpoint: https://mcp.alirezasafaeisystems.ir/sse/
```

## Initial scope

The first release is intentionally read-only:

- list repositories
- summarize repository metadata
- search code
- read repository files
- list issues
- list pull requests

No write, delete, merge, deploy, or destructive operation is exposed in this stage.

## ChatGPT connector form

Use the following values in ChatGPT Settings → Connectors → Advanced → New App:

```text
Name: ASDEV GitHub Assistant
Description: Helps analyze ASDEV GitHub repositories, project files, issues, pull requests, commits, and development workflows.
Connection: Server URL
Authentication: None for private testing; OAuth later for production/team use
Server URL: https://mcp.alirezasafaeisystems.ir/sse/
```

This scaffold runs FastMCP with SSE transport and exposes `/sse/`.

## Domain vs IP

Recommended and selected:

```text
https://mcp.alirezasafaeisystems.ir/sse/
```

Do not use a raw IP for the final ChatGPT connector. Use the configured subdomain with a valid public TLS certificate.

A raw IP is acceptable only for very short internal testing when it is still reachable over valid HTTPS. Plain HTTP is not acceptable for production connector usage.

## Environment

Copy the example file:

```bash
cp .env.example .env
```

Required:

```bash
GITHUB_TOKEN=github_pat_xxx
GITHUB_OWNER=alirezasafaei-dev
```

Recommended allow-list:

```bash
ALLOWED_REPOS=alirezasafaei-dev/alirezasafaeisystems,alirezasafaei-dev/auditsystems,alirezasafaei-dev/persiantoolbox,alirezasafaei-dev/devatlas
MAX_FILE_BYTES=200000
```

Use a minimum-permission GitHub token. Never commit `.env`.

## Local run

```bash
cd tools/asdev-chatgpt-mcp
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python server.py
```

The service listens on port `8000`.

## Server deployment without Docker

Recommended layout on the automation server:

```text
/home/asdev/apps/asdev-chatgpt-mcp
```

Deployment flow:

```bash
ssh asdev@91.107.153.223
mkdir -p ~/apps
cd ~/apps

# clone if missing, otherwise pull/update the existing repo
if [ ! -d alirezasafaeisystems ]; then
  git clone git@github.com:alirezasafaei-dev/alirezasafaeisystems.git
fi
cd alirezasafaeisystems
git fetch origin
git checkout feat/asdev-chatgpt-mcp
git pull --ff-only origin feat/asdev-chatgpt-mcp

cd tools/asdev-chatgpt-mcp
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
cp -n .env.example .env
nano .env
```

Run manually for smoke testing:

```bash
source .venv/bin/activate
python server.py
```

After smoke testing, install a systemd service using `deploy/systemd/asdev-chatgpt-mcp.service.example`.

## Reverse proxy

Expose the local service through Nginx or Caddy:

```text
127.0.0.1:8000 → https://mcp.alirezasafaeisystems.ir/sse/
```

Example configs live under:

```text
tools/asdev-chatgpt-mcp/deploy/nginx/
tools/asdev-chatgpt-mcp/deploy/caddy/
```

## Hardening plan

Before exposing this to anyone else:

1. Add OAuth or a reverse-proxy auth layer.
2. Keep the server read-only unless a specific write tool is approved.
3. Add structured audit logs without storing secrets.
4. Restrict repositories with `ALLOWED_REPOS`.
5. Use a low-scope GitHub token.
6. Add rate limiting at the reverse proxy.
