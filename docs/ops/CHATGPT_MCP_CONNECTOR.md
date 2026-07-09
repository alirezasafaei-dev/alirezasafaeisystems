# ChatGPT MCP Connector for ASDEV

## Decision

Run a dedicated read-only MCP server for ChatGPT Developer Mode under the ASDEV mother repository.

Recommended public endpoint:

```text
https://mcp.alirezasafaeisystems.ir/sse/
```

## Why domain instead of raw IP

Use a domain/subdomain for the final connector because:

- HTTPS certificate management is standard and renewable.
- The service can move to another server without changing the ChatGPT app configuration strategy.
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

## Current implementation path

```text
tools/asdev-chatgpt-mcp/
```

## First release constraints

- Read-only only.
- No GitHub writes.
- No deploy actions.
- No secret exposure.
- Repositories restricted by `ALLOWED_REPOS`.
- GitHub token stored only on the server in `.env`.

## Deployment checklist

1. Create DNS record:

```text
mcp.alirezasafaeisystems.ir A SERVER_IP
```

2. SSH into the server.
3. Clone or pull the repo branch.
4. Configure `.env`.
5. Run Docker Compose.
6. Configure Caddy or Nginx.
7. Enable HTTPS.
8. Test endpoint reachability.
9. Add the endpoint in ChatGPT Developer Mode.
10. Review discovered tools before enabling the app.

## Future hardening

- OAuth support.
- Audit logs.
- Rate limiting.
- Per-tool allow policy.
- Read-only token scopes.
- Separate deployment user.
- Container resource limits.
