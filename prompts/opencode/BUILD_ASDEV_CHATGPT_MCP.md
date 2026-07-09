# OpenCode Prompt — Build ASDEV ChatGPT MCP Connector

Use this prompt with OpenCode CLI from the root of `alirezasafaei-dev/alirezasafaeisystems`.

```text
You are working inside the canonical ASDEV mother repository:

Repository: alirezasafaei-dev/alirezasafaeisystems
Primary product focus: ASDEV Audit Platform
Goal: implement a production-ready, read-only MCP server that lets ChatGPT Developer Mode inspect ASDEV GitHub repositories safely.

Non-negotiable rules:
1. Do not touch unrelated product code.
2. Do not change the Next.js website unless documentation links are needed.
3. Do not add destructive tools.
4. Do not expose write operations.
5. Do not commit secrets.
6. Do not hardcode tokens.
7. Do not weaken existing ASDEV governance or AGENTS rules.
8. Keep the first version read-only.
9. Prefer small, reviewable changes.
10. If anything is ambiguous, implement the safest read-only option and document the limitation.

Required deliverable:
Create or improve this folder:

tools/asdev-chatgpt-mcp/

The MCP server must expose these tools:
- list_repositories(limit?: number)
- get_repository_summary(repository: string)
- search_code(query: string, repository?: string)
- read_file(repository: string, path: string, branch?: string)
- list_issues(repository: string, state?: open|closed|all)
- list_pull_requests(repository: string, state?: open|closed|all)

Implementation requirements:
- Python 3.12
- FastMCP or the most current stable MCP Python server package available in the project environment
- Dockerfile
- docker-compose.yml
- .env.example
- README.md
- reverse proxy examples for Caddy and/or Nginx
- documentation in docs/ops/CHATGPT_MCP_CONNECTOR.md

Security requirements:
- Read GitHub token from GITHUB_TOKEN only.
- Read owner from GITHUB_OWNER, default alirezasafaei-dev.
- Enforce ALLOWED_REPOS if set.
- Reject repositories outside the configured owner.
- Reject path traversal in read_file.
- Limit file reads using MAX_FILE_BYTES.
- Never print token values.
- Never include token values in errors.
- Bind docker-compose to 127.0.0.1:8000, not public 0.0.0.0, because reverse proxy handles public access.

Recommended connector endpoint:
https://mcp.alirezasafaeisystems.ir/sse/

Domain policy:
- Final connector must use a domain/subdomain with valid HTTPS.
- Raw IP is only acceptable for temporary testing if valid HTTPS is available.
- Plain HTTP is not acceptable for the ChatGPT connector.

Validation tasks:
1. Inspect current repository structure.
2. Read README.md, ASDEV.md, AGENTS.md, and docs/strategy/FOCUS_POLICY.md if present.
3. Implement the MCP server without breaking the existing Next.js app.
4. Run syntax checks for Python.
5. If Docker is available, build the MCP image.
6. If pnpm is available, run existing website checks only if touched files require it.
7. Produce a final report with:
   - files changed
   - exact run commands
   - exact ChatGPT connector URL
   - security limitations
   - next steps for OAuth

Expected final ChatGPT form values:
Name: ASDEV GitHub Assistant
Description: Helps analyze ASDEV GitHub repositories, project files, issues, pull requests, commits, and development workflows.
Connection: Server URL
Authentication: None for private testing; OAuth later for production/team use
Server URL: https://mcp.alirezasafaeisystems.ir/sse/

Do not merge automatically. Leave changes in a branch or PR for human review.
```
