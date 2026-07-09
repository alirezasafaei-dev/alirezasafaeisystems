# OpenCode Prompt — Deploy ASDEV ChatGPT MCP on Automation Server

Use this prompt with OpenCode CLI. The agent must work on the automation server, not only locally.

```text
You are an autonomous implementation agent for ASDEV.

Mission:
Deploy a production-usable, read-only ChatGPT MCP server for ASDEV GitHub inspection on the automation server.

Canonical repository:
alirezasafaei-dev/alirezasafaeisystems

Automation server:
asdev@91.107.153.223

Final domain:
mcp.alirezasafaeisystems.ir

Final public ChatGPT connector endpoint:
https://mcp.alirezasafaeisystems.ir/sse/

Critical instruction:
You MUST perform the work on the automation server. Do not stop after editing files in the repository. You must SSH into `asdev@91.107.153.223`, deploy the service there, configure process management and reverse proxy, test the public HTTPS endpoint, and produce a final operational report.

Deployment mode:
NO DOCKER for now.
Use Python virtualenv + systemd + Nginx or Caddy.
Do not create Dockerfile.
Do not use docker compose.
Do not install or depend on Docker.

Non-negotiable safety rules:
1. Do not touch unrelated product code.
2. Do not change the Next.js website unless a documentation link is strictly required.
3. Do not add destructive MCP tools.
4. Do not expose write operations through MCP.
5. Do not commit secrets.
6. Do not hardcode tokens.
7. Do not print tokens in logs or final output.
8. Do not weaken existing ASDEV governance or AGENTS rules.
9. Keep the first version read-only.
10. Do not run broad destructive shell commands.
11. Do not overwrite existing server services without backing up the relevant config.
12. If root/sudo is needed, explain exactly which command needs it and why.

Required MCP tools:
- list_repositories(limit?: number)
- get_repository_summary(repository: string)
- search_code(query: string, repository?: string)
- read_file(repository: string, path: string, branch?: string)
- list_issues(repository: string, state?: open|closed|all)
- list_pull_requests(repository: string, state?: open|closed|all)

Implementation requirements:
- Python 3.12 if available, otherwise use the newest installed Python 3 version >= 3.10 and document it.
- FastMCP or the most current stable MCP Python server package available.
- `.env.example`
- `README.md`
- `deploy/systemd/asdev-chatgpt-mcp.service.example`
- reverse proxy example for Nginx or Caddy
- `docs/ops/CHATGPT_MCP_CONNECTOR.md`
- no Docker files

Security requirements:
- Read GitHub token from `GITHUB_TOKEN` only.
- Read owner from `GITHUB_OWNER`, default `alirezasafaei-dev`.
- Enforce `ALLOWED_REPOS` if set.
- Reject repositories outside the configured owner.
- Reject path traversal in `read_file`.
- Limit file reads using `MAX_FILE_BYTES`.
- Bind the app locally on `127.0.0.1` or protect public access through reverse proxy only.
- Store `.env` only on the server.
- Never commit `.env`.

Required server-side deployment path:
Prefer:
/home/asdev/apps/alirezasafaeisystems

MCP app path inside repo:
/home/asdev/apps/alirezasafaeisystems/tools/asdev-chatgpt-mcp

Required server execution plan:
1. SSH into `asdev@91.107.153.223`.
2. Print hostname, current user, OS release, Python version, and available reverse proxies.
3. Confirm DNS for `mcp.alirezasafaeisystems.ir` points to `91.107.153.223`.
4. Create `/home/asdev/apps` if missing.
5. Clone `git@github.com:alirezasafaei-dev/alirezasafaeisystems.git` if missing.
6. If repo exists, fetch and checkout the correct branch.
7. Create or update the MCP server under `tools/asdev-chatgpt-mcp/`.
8. Create `.venv` and install dependencies.
9. Create `.env` from `.env.example` if missing. If `GITHUB_TOKEN` is missing, stop and ask for it; do not invent it.
10. Run Python syntax checks.
11. Run the MCP server manually for a local smoke test.
12. Install a systemd service named `asdev-chatgpt-mcp.service`.
13. Start and enable the service.
14. Check `systemctl status asdev-chatgpt-mcp --no-pager`.
15. Configure Nginx or Caddy for `mcp.alirezasafaeisystems.ir` to reverse proxy to `127.0.0.1:8000`.
16. Enable HTTPS with a valid certificate.
17. Test local endpoint with curl.
18. Test public endpoint: `https://mcp.alirezasafaeisystems.ir/sse/`.
19. Do not mark the task complete unless the public HTTPS endpoint responds or you clearly report the exact blocker.

Expected ChatGPT form values after deployment:
Name: ASDEV GitHub Assistant
Description: Helps analyze ASDEV GitHub repositories, project files, issues, pull requests, commits, and development workflows.
Connection: Server URL
Authentication: None for private testing; OAuth later for production/team use
Server URL: https://mcp.alirezasafaeisystems.ir/sse/

Validation checklist before final answer:
- `git status` clean or list exact uncommitted files.
- Python syntax check passed.
- systemd service active or exact reason it is not.
- reverse proxy config tested or exact reason it is not.
- HTTPS certificate active or exact reason it is not.
- public MCP endpoint tested or exact error captured.
- No secrets printed.
- No Docker used.

Final report format:
1. Server actions performed
2. Files changed
3. Commands run
4. Service status
5. Public endpoint test result
6. ChatGPT connector values
7. Remaining blockers, if any
8. Security limitations and next hardening step

Do not merge automatically. Leave code changes in a branch or PR for human review unless explicitly instructed to merge.
```
