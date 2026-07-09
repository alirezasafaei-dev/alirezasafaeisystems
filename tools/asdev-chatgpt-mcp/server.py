import os
from typing import Any
from urllib.parse import quote

import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP

load_dotenv()

OWNER = os.getenv("GITHUB_OWNER", "alirezasafaei-dev").strip()
TOKEN = os.getenv("GITHUB_TOKEN", "").strip()
MAX_FILE_BYTES = int(os.getenv("MAX_FILE_BYTES", "200000"))
ALLOWED_REPOS = {
    item.strip()
    for item in os.getenv("ALLOWED_REPOS", "").split(",")
    if item.strip()
}

GITHUB_API = "https://api.github.com"

mcp = FastMCP(
    name="ASDEV GitHub Assistant",
    instructions=(
        "Read-only assistant for ASDEV GitHub repository analysis. "
        "Never expose secrets. Never perform write, delete, merge, or deploy actions."
    ),
)


def github_headers(accept: str = "application/vnd.github+json") -> dict[str, str]:
    headers = {
        "Accept": accept,
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "asdev-chatgpt-mcp",
    }
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    return headers


def normalize_repo(repository: str) -> str:
    repo = repository.strip()
    if not repo:
        raise ValueError("repository is required")
    if "/" not in repo:
        repo = f"{OWNER}/{repo}"
    if not repo.startswith(f"{OWNER}/"):
        raise ValueError("Repository owner is not allowed")
    if ALLOWED_REPOS and repo not in ALLOWED_REPOS:
        raise ValueError("Repository is not in ALLOWED_REPOS")
    return repo


def safe_path(path: str) -> str:
    clean = path.strip().strip("/")
    if not clean:
        raise ValueError("path is required")
    parts = clean.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise ValueError("invalid path")
    return clean


async def github_json(path: str, params: dict[str, Any] | None = None) -> Any:
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{GITHUB_API}{path}",
            headers=github_headers(),
            params=params,
        )
        response.raise_for_status()
        return response.json()


async def github_text(path: str, params: dict[str, Any] | None = None) -> str:
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{GITHUB_API}{path}",
            headers=github_headers("application/vnd.github.raw"),
            params=params,
        )
        response.raise_for_status()
        text = response.text
        if len(text.encode("utf-8")) > MAX_FILE_BYTES:
            raise ValueError(f"file is larger than MAX_FILE_BYTES={MAX_FILE_BYTES}")
        return text


@mcp.tool()
async def list_repositories(limit: int = 20) -> list[dict[str, Any]]:
    """List repositories owned by the configured ASDEV GitHub account."""
    data = await github_json(
        "/user/repos",
        params={
            "affiliation": "owner",
            "sort": "updated",
            "direction": "desc",
            "per_page": min(max(limit, 1), 100),
        },
    )
    repos = []
    for repo in data:
        if repo.get("owner", {}).get("login") != OWNER:
            continue
        full_name = repo["full_name"]
        if ALLOWED_REPOS and full_name not in ALLOWED_REPOS:
            continue
        repos.append(
            {
                "full_name": full_name,
                "private": repo.get("private"),
                "archived": repo.get("archived"),
                "description": repo.get("description"),
                "default_branch": repo.get("default_branch"),
                "language": repo.get("language"),
                "updated_at": repo.get("updated_at"),
                "html_url": repo.get("html_url"),
            }
        )
    return repos


@mcp.tool()
async def get_repository_summary(repository: str) -> dict[str, Any]:
    """Return safe repository metadata for one ASDEV repository."""
    repo = normalize_repo(repository)
    data = await github_json(f"/repos/{repo}")
    return {
        "full_name": data.get("full_name"),
        "description": data.get("description"),
        "private": data.get("private"),
        "archived": data.get("archived"),
        "default_branch": data.get("default_branch"),
        "language": data.get("language"),
        "stars": data.get("stargazers_count"),
        "forks": data.get("forks_count"),
        "open_issues": data.get("open_issues_count"),
        "updated_at": data.get("updated_at"),
        "html_url": data.get("html_url"),
    }


@mcp.tool()
async def read_file(repository: str, path: str, branch: str = "") -> dict[str, str]:
    """Read a UTF-8 text file from an allowed ASDEV repository."""
    repo = normalize_repo(repository)
    clean_path = safe_path(path)
    encoded_path = quote(clean_path, safe="/")
    params = {"ref": branch.strip()} if branch.strip() else None
    content = await github_text(f"/repos/{repo}/contents/{encoded_path}", params=params)
    return {"repository": repo, "path": clean_path, "content": content}


@mcp.tool()
async def search_code(query: str, repository: str = "") -> list[dict[str, str | None]]:
    """Search code across allowed ASDEV repositories or inside one repository."""
    clean_query = query.strip()
    if not clean_query:
        raise ValueError("query is required")

    if repository.strip():
        q = f"{clean_query} repo:{normalize_repo(repository)}"
    elif ALLOWED_REPOS:
        repo_filters = " ".join(f"repo:{repo}" for repo in ALLOWED_REPOS)
        q = f"{clean_query} {repo_filters}"
    else:
        q = f"{clean_query} user:{OWNER}"

    data = await github_json("/search/code", params={"q": q, "per_page": 10})
    return [
        {
            "name": item.get("name"),
            "path": item.get("path"),
            "repository": item.get("repository", {}).get("full_name"),
            "html_url": item.get("html_url"),
        }
        for item in data.get("items", [])
    ]


@mcp.tool()
async def list_issues(repository: str, state: str = "open") -> list[dict[str, Any]]:
    """List issues for an allowed ASDEV repository."""
    repo = normalize_repo(repository)
    issue_state = state if state in {"open", "closed", "all"} else "open"
    data = await github_json(
        f"/repos/{repo}/issues",
        params={"state": issue_state, "per_page": 20},
    )
    return [
        {
            "number": item.get("number"),
            "title": item.get("title"),
            "state": item.get("state"),
            "created_at": item.get("created_at"),
            "updated_at": item.get("updated_at"),
            "html_url": item.get("html_url"),
        }
        for item in data
        if "pull_request" not in item
    ]


@mcp.tool()
async def list_pull_requests(repository: str, state: str = "open") -> list[dict[str, Any]]:
    """List pull requests for an allowed ASDEV repository."""
    repo = normalize_repo(repository)
    pr_state = state if state in {"open", "closed", "all"} else "open"
    data = await github_json(
        f"/repos/{repo}/pulls",
        params={"state": pr_state, "per_page": 20},
    )
    return [
        {
            "number": item.get("number"),
            "title": item.get("title"),
            "state": item.get("state"),
            "draft": item.get("draft"),
            "created_at": item.get("created_at"),
            "updated_at": item.get("updated_at"),
            "html_url": item.get("html_url"),
        }
        for item in data
    ]


if __name__ == "__main__":
    mcp.run(transport="sse", host="0.0.0.0", port=8000)
