# ASDEV ChatGPT MCP Server

Read-only MCP server scaffold for connecting ChatGPT Developer Mode to the ASDEV GitHub workspace.

This belongs in the ASDEV mother repository because this repository is the canonical parent brand, governance, and agent-rules source for ASDEV.

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

The exact endpoint depends on the MCP transport you run. This scaffold runs FastMCP with SSE transport and exposes `/sse/`.

## Domain vs IP

Recommended:

```text
https://mcp.alirezasafaeisystems.ir/sse/
```

Do not use a raw IP for the final ChatGPT connector. Use a domain/subdomain with a valid public TLS certificate.

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
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python server.py
```

The service listens on port `8000`.

## Docker run

```bash
cd tools/asdev-chatgpt-mcp
cp .env.example .env
# edit .env
docker compose up -d --build
```

## VPS deployment outline

1. Create DNS record:

```text
mcp.alirezasafaeisystems.ir A YOUR_SERVER_IP
```

2. Deploy the container.
3. Put Caddy or Nginx in front of it.
4. Enable HTTPS.
5. Put this URL into ChatGPT:

```text
https://mcp.alirezasafaeisystems.ir/sse/
```

## Hardening plan

Before exposing this to anyone else:

1. Add OAuth or a reverse-proxy auth layer.
2. Keep the server read-only unless a specific write tool is approved.
3. Add structured audit logs without storing secrets.
4. Restrict repositories with `ALLOWED_REPOS`.
5. Use a low-scope GitHub token.
6. Add rate limiting at the reverse proxy.
