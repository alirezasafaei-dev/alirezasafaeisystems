# Change Detection Rules

**Purpose:** Optimize deployments by detecting what changed and only running necessary steps.

---

## Detection Logic

The deploy script analyzes git diff between parent and target commit to determine change type:

| Pattern | Change Type | Action |
|---------|-------------|--------|
| `*.md`, `*.txt`, `docs/*` | docs | Logged only |
| `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.py`, `*.rb`, `*.go`, `src/*`, `app/*`, `lib/*` | source | Full build |
| `*.env*`, `*.json`, `*.yaml`, `*.yml`, `*.toml`, `config/*` | config | Full build |
| `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `requirements.txt` | deps | Full build |
| No matching pattern | other | Full build (safe default) |

---

## Benefits

1. **Docs-only changes:** Logged without triggering build
2. **Source changes:** Full build for safety
3. **Config changes:** Full build for security
4. **Unknown changes:** Full build as safe default

---

## Implementation

Change detection is built into `scripts/deploy/asdev-deploy.sh`:

```bash
detect_changes() {
    local repo_path="$1" commit="$2"
    # git diff between commit^ and commit
    # Classifies files into: source, config, deps, docs, other
}
```

The detected change type is logged but does not skip the build — the build command from the registry is always executed for safety.

---

## Change Impact Assessment

| Category | Change Type | Notes |
|----------|-------------|-------|
| docs | docs | Documentation only |
| source | source | Application source code |
| config | config | Configuration files |
| deps | deps | Dependency lockfiles |
| other | other | Unrecognized patterns |

---

## Usage

Change detection runs automatically during deployment. To preview changes:

```bash
./scripts/deploy/asdev-deploy.sh --site auditsystems --environment staging --commit abc1234 --check
```

This outputs the change type without executing any deployment actions.
