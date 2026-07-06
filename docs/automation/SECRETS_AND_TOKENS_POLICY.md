# Secrets and Tokens Policy — ASDEV Automation

**Status:** Active (2026-07-06)
**Scope:** All ASDEV automation scripts and configs

---

## Rules

1. **Never commit secrets** — no API keys, tokens, passwords, or credentials in git
2. **Use environment variables** — all secrets come from env vars or `gh auth`
3. **Use .env files locally** — never commit `.env` files
4. **Document placeholders only** — `env.example` has `change-me` values

---

## Token Sources (in order of preference)

### 1. GitHub CLI auth (recommended)

```bash
gh auth login
```

Scripts use `gh` which inherits auth from the CLI. No token needed in env.

### 2. Environment variable

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

Set in shell session or `.env` file (not committed).

### 3. Secret manager (future)

For production automation, use a secret manager:
- GitHub Actions secrets
- AWS Secrets Manager
- HashiCorp Vault

---

## What Scripts Access

| Script | Tokens Used | Source |
|---|---|---|
| `monitor-pr.sh` | GitHub API (via `gh`) | `gh auth` or `GH_TOKEN` |
| `create-kanban-task.sh` | None | Local Hermes |
| `dispatch-hermes-task.sh` | Hermes API key | `~/.hermes/config.yaml` |
| `post-agent-report.sh` | GitHub API (via `gh`) | `gh auth` or `GH_TOKEN` |
| `dry-run-loop.sh` | GitHub API + Hermes | Above sources |

---

## Forbidden

- ❌ Hardcoded tokens in scripts
- ❌ Tokens in commit messages
- ❌ Tokens in PR comments
- ❌ Tokens in kanban task bodies
- ❌ `.env` files in git
- ❌ `GITHUB_TOKEN` in `env.example` (use `change-me`)

---

## Checking for Leaks

Before committing:

```bash
grep -r "password\|secret\|api_key\|token\|sk-\|ghp_" scripts/ ops/
```

Should return empty or only `env.example` with `change-me` values.

---

## Incident Response

If a secret is accidentally committed:

1. **Immediately** rotate the secret
2. Remove from git history (force push if needed)
3. Report on PR #42
4. Update this policy if needed

---

*Policy version: Phase P2 (2026-07-06)*
