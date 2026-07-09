# ASDEV ChatGPT MCP Server

Read-only [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server
that allows ChatGPT and any MCP-compatible client to inspect ASDEV GitHub
repositories.

## Tools

| Tool                     | Description                                        |
|--------------------------|----------------------------------------------------|
| `list_repositories`      | List all repositories for the configured owner     |
| `get_repository_summary` | Detailed metadata + stats for a repo               |
| `search_code`            | Search code across repos (GitHub code search)      |
| `read_file`              | Read a single file from a repo                     |
| `list_issues`            | List issues (open / closed / all)                  |
| `list_pull_requests`     | List pull requests (open / closed / all)           |

All tools are **read-only**. No write operations are exposed.

## Quick start

```bash
cd tools/asdev-chatgpt-mcp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env and set GITHUB_TOKEN

python server.py
```

The server listens on `http://127.0.0.1:8000` and serves the MCP SSE protocol
at `/sse`.

## Deployment

See [`docs/ops/CHATGPT_MCP_CONNECTOR.md`](../../docs/ops/CHATGPT_MCP_CONNECTOR.md)
for the full deployment guide, including systemd service, reverse proxy, and
HTTPS setup.

## Security

- The server binds to `127.0.0.1` by default — never expose port 8000 directly.
- Put it behind a reverse proxy (Nginx / Caddy) with TLS.
- Repository access is scoped to `GITHUB_OWNER` and can be further restricted
  with `ALLOWED_REPOS`.
- Path traversal in `read_file` is rejected.
- File reads are limited by `MAX_FILE_BYTES` (default 1 MiB).
- The GitHub token is read from the `GITHUB_TOKEN` environment variable only.
