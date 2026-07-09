#!/usr/bin/env python3
"""ASDEV ChatGPT MCP Server — Read-only GitHub inspection via Model Context Protocol.

This server exposes MCP tools that allow ChatGPT (and any MCP-compatible client)
to inspect ASDEV GitHub repositories, read files, search code, and list
issues / pull requests.  All operations are read-only.

Usage
-----
    # Install dependencies
    pip install -r requirements.txt

    # Copy and populate environment
    cp .env.example .env
    # Set GITHUB_TOKEN in .env

    # Run (SSE transport, suitable for ChatGPT MCP connector)
    python server.py

Environment variables
---------------------
    GITHUB_TOKEN     : GitHub personal access token (required)
    GITHUB_OWNER     : GitHub owner/org (default: alirezasafaei-dev)
    ALLOWED_REPOS    : Comma-separated whitelist (optional; defaults to all under GITHUB_OWNER)
    MAX_FILE_BYTES   : Maximum file read size in bytes (default: 1_048_576)
    BIND_HOST        : Bind address (default: 127.0.0.1)
    BIND_PORT        : Bind port (default: 8000)
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from github import Auth, Github, GithubException
from mcp.server import FastMCP

# Load .env file if present (development convenience; production uses env vars directly)
load_dotenv(Path(__file__).resolve().parent / ".env")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_OWNER = os.environ.get("GITHUB_OWNER", "alirezasafaei-dev")

_raw_allowed = os.environ.get("ALLOWED_REPOS", "")
ALLOWED_REPOS: set[str] = {r.strip() for r in _raw_allowed.split(",") if r.strip()}

MAX_FILE_BYTES = int(os.environ.get("MAX_FILE_BYTES", str(1_048_576)))
BIND_HOST = os.environ.get("BIND_HOST", "127.0.0.1")
BIND_PORT = int(os.environ.get("BIND_PORT", "8000"))

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

if not GITHUB_TOKEN:
    print("FATAL: GITHUB_TOKEN environment variable is required.", file=sys.stderr)
    sys.exit(1)

gh = Github(auth=Auth.Token(GITHUB_TOKEN))

try:
    gh.get_user().login
except GithubException as exc:
    print(f"FATAL: GitHub token validation failed: {exc}", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Access-control helpers
# ---------------------------------------------------------------------------


def _qualify(name: str) -> str:
    """Return owner-qualified name if ``name`` is not already qualified."""
    return name if "/" in name else f"{GITHUB_OWNER}/{name}"


def _check_repo(name: str) -> None:
    """Raise :class:`ValueError` if *name* is not permitted."""
    full = _qualify(name)
    if ALLOWED_REPOS:
        if name not in ALLOWED_REPOS and full not in ALLOWED_REPOS:
            raise ValueError(f"Repository '{name}' is not in ALLOWED_REPOS")
    elif not full.startswith(f"{GITHUB_OWNER}/"):
        raise ValueError(f"Repository '{name}' is not under owner '{GITHUB_OWNER}'")


def _get_repo(name: str):
    """Return a PyGithub :class:`Repository` object after access control."""
    _check_repo(name)
    return gh.get_repo(_qualify(name))


# ---------------------------------------------------------------------------
# MCP server instance
# ---------------------------------------------------------------------------

mcp = FastMCP("ASDEV GitHub Assistant")

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------


@mcp.tool()
def list_repositories(limit: Optional[int] = None) -> list[dict]:
    """List all repositories for the configured GitHub owner.

    Args:
        limit: Maximum number of repositories to return (default: all).
    """
    try:
        owner = gh.get_user(GITHUB_OWNER)
        repos = owner.get_repos()
        out: list[dict] = []
        for i, r in enumerate(repos):
            if limit is not None and i >= limit:
                break
            out.append(
                {
                    "name": r.name,
                    "full_name": r.full_name,
                    "description": r.description,
                    "url": r.html_url,
                    "stars": r.stargazers_count,
                    "forks": r.forks_count,
                    "language": r.language,
                    "private": r.private,
                    "archived": r.archived,
                }
            )
        return out
    except GithubException as exc:
        return {"error": str(exc)}


@mcp.tool()
def get_repository_summary(repository: str) -> dict:
    """Get a detailed summary of a repository.

    Args:
        repository: Repository name (with or without owner prefix).
    """
    try:
        r = _get_repo(repository)
        return {
            "name": r.name,
            "full_name": r.full_name,
            "description": r.description,
            "url": r.html_url,
            "stars": r.stargazers_count,
            "forks": r.forks_count,
            "open_issues": r.open_issues_count,
            "language": r.language,
            "topics": r.get_topics(),
            "license": r.license.name if r.license else None,
            "default_branch": r.default_branch,
            "created_at": _dt(r.created_at),
            "updated_at": _dt(r.updated_at),
            "pushed_at": _dt(r.pushed_at),
            "size_kb": r.size,
            "private": r.private,
            "archived": r.archived,
        }
    except Exception as exc:
        return {"error": str(exc)}


@mcp.tool()
def search_code(query: str, repository: Optional[str] = None) -> list[dict]:
    """Search code across the owner's repos, optionally scoped to one repo.

    Args:
        query: GitHub code-search query string.
        repository: Optional repo name to scope search within.
    """
    try:
        q = f"{query} org:{GITHUB_OWNER}"
        if repository:
            _check_repo(repository)
            q = f"{query} repo:{_qualify(repository)}"
        results = gh.search_code(q)
        return [
            {
                "repository": item.repository.full_name,
                "path": item.path,
                "url": item.html_url,
            }
            for item in results[:20]
        ]
    except GithubException as exc:
        return {"error": str(exc)}


@mcp.tool()
def read_file(repository: str, path: str, branch: Optional[str] = None) -> dict:
    """Read a file from a repository.

    Path-traversal sequences (``..``) are rejected.  Files larger than
    ``MAX_FILE_BYTES`` are not returned.

    Args:
        repository: Repository name.
        path: File path within the repository.
        branch: Branch or ref (default: repository default branch).
    """
    if ".." in path.split("/"):
        return {"error": "Path traversal detected: '..' is not allowed in path."}
    normalized = os.path.normpath("/" + path).lstrip("/")
    if normalized != path.strip("/"):
        return {"error": "Path traversal detected: normalized path differs."}
    try:
        r = _get_repo(repository)
        kwargs: dict = {}
        if branch:
            kwargs["ref"] = branch
        cf = r.get_contents(path, **kwargs)
        if cf.size > MAX_FILE_BYTES:
            return {
                "error": f"File too large ({cf.size} bytes). Maximum allowed: {MAX_FILE_BYTES} bytes."
            }
        content = cf.decoded_content.decode("utf-8", errors="replace")
        return {"path": path, "size": cf.size, "content": content}
    except Exception as exc:
        return {"error": str(exc)}


@mcp.tool()
def list_issues(repository: str, state: str = "open") -> list[dict]:
    """List issues for a repository.

    Args:
        repository: Repository name.
        state: Filter — ``"open"``, ``"closed"``, or ``"all"`` (default ``"open"``).
    """
    try:
        r = _get_repo(repository)
        return [
            {
                "number": i.number,
                "title": i.title,
                "state": i.state,
                "author": i.user.login,
                "labels": [l.name for l in i.labels],
                "created_at": _dt(i.created_at),
                "updated_at": _dt(i.updated_at),
                "url": i.html_url,
            }
            for i in r.get_issues(state=state)[:20]
        ]
    except Exception as exc:
        return {"error": str(exc)}


@mcp.tool()
def list_pull_requests(repository: str, state: str = "open") -> list[dict]:
    """List pull requests for a repository.

    Args:
        repository: Repository name.
        state: Filter — ``"open"``, ``"closed"``, or ``"all"`` (default ``"open"``).
    """
    try:
        r = _get_repo(repository)
        return [
            {
                "number": pr.number,
                "title": pr.title,
                "state": pr.state,
                "author": pr.user.login,
                "created_at": _dt(pr.created_at),
                "updated_at": _dt(pr.updated_at),
                "merged": pr.merged,
                "draft": pr.draft,
                "url": pr.html_url,
            }
            for pr in r.get_pulls(state=state)[:20]
        ]
    except Exception as exc:
        return {"error": str(exc)}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _dt(d):
    """Return ISO-8601 string or ``None``."""
    return d.isoformat() if d else None


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn

    app = mcp.sse_app()
    uvicorn.run(app, host=BIND_HOST, port=BIND_PORT)
