# ChatGPT MCP Connector for ASDEV

## Decision

Run a dedicated read-only MCP server for ChatGPT Developer Mode under the ASDEV mother repository, deployed directly on the ASDEV automation server without Docker.

Target:

```text
SSH user/host: asdev@91.107.153.223
Domain: mcp.alirezasafaeisystems.ir
Public endpoint: https://mcp.alirezasafaeisystems.ir/sse/
Implementation path: tools/asdev-chatgpt-mcp/
```

## Why domain instead of raw IP

Use the configured subdomain for the final connector because:

- The ChatGPT connector expects a public HTTPS MCP endpoint.
- TLS certificate management is standard and renewable on a domain.
- The service can move to another server without changing the public connector identity.
- OAuth, reverse proxy rules, rate limiting, and logs are cleaner.
- It separates the MCP service from the main production website and audit product.

A raw IP is acceptable only for short testing if the URL still has valid HTTPS. Do not use plain HTTP.

## App settings in ChatGPT

```text
Name: ASDEV GitHub Assistant
Description: Helps analyze ASDEV GitHub repositories, project files, issues, pull requests, commits, and development workflows.
Connection: Server URL
Authentication: None for private testing; OAuth later for production/team use
Server URL: https://mcp.alirezasafaeisystems.ir/sse/
```

## First release constraints

- Read-only only.
- No GitHub writes.
- No deploy actions exposed as MCP tools.
- No secret exposure.
- Repositories restricted by `ALLOWED_REPOS`.
- GitHub token stored only on the server in `.env`.
- No Docker for the first deployment.

## Non-Docker deployment checklist

1. Confirm DNS:

```text
mcp.alirezasafaeisystems.ir A 91.107.153.223
```

2. SSH into the automation server:

```bash
ssh asdev@91.107.153.223
```

3. Clone or update the mother repo under `/home/asdev/apps/alirezasafaeisystems`.
4. Checkout the MCP branch or merge it after review.
5. Create a Python virtual environment in `tools/asdev-chatgpt-mcp/.venv`.
6. Install dependencies from `requirements.txt`.
7. Create `.env` from `.env.example` and configure `GITHUB_TOKEN`.
8. Run `python server.py` for a manual smoke test.
9. Install the systemd service from `deploy/systemd/asdev-chatgpt-mcp.service.example`.
10. Configure Caddy or Nginx to reverse-proxy `mcp.alirezasafaeisystems.ir` to `127.0.0.1:8000`.
11. Enable HTTPS.
12. Test `https://mcp.alirezasafaeisystems.ir/sse/`.
13. Add the endpoint in ChatGPT Developer Mode.
14. Review discovered tools before enabling the app.

## Future hardening

- OAuth support.
- Audit logs.
- Rate limiting.
- Per-tool allow policy.
- Read-only token scopes.
- Separate deployment user.
- Systemd sandboxing and resource limits.
