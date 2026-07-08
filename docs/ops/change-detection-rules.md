# Change Detection Rules

**Purpose:** Optimize deployments by detecting what changed and only running necessary steps.

---

## Detection Logic

The deploy script analyzes git diff between current and new commit to determine change type:

| Pattern | Change Type | Action |
|---------|-------------|--------|
| `*.md`, `*.txt`, `*.pdf` | docs | No deploy needed |
| `*.css`, `*.scss`, `*.html` | assets | Deploy changed assets, skip build if framework allows |
| `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | deps | Run dependency install |
| `package.json` | deps | Run dependency install |
| `*.js`, `*.ts`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte` | source | Run full build |
| `*.env`, `*.config`, `*.yml`, `*.yaml`, `*.toml` | config | Require manual review |
| Database/schema/migration | migration | Block, require separate approval |
| No matching pattern | unknown | Run full build (safe default) |

---

## Benefits

1. **Docs-only changes:** Zero deploy time
2. **Static asset changes:** Skip dependency install
3. **Dependency changes:** Skip build if no source changes
4. **Source changes:** Full build for safety
5. **Config changes:** Force manual review for security

---

## Implementation

Change detection is built into `scripts/deploy/asdev-deploy.sh`:

```bash
detect_changes() {
    local repo_path="${DEPLOY_DIR}/${SITE}/repo"
    # ... analyzes git diff ...
}
```

The detected change type influences:
- Whether `npm ci` / `yarn install` / `pnpm install` runs
- Whether `npm run build` runs
- Metadata recorded in release history

---

## Change Impact Assessment

| Category | Impact Level | Required Approval |
|----------|--------------|-------------------|
| docs | Low | Standard |
| assets | Low | Standard |
| deps | Medium | Standard |
| source | High | Standard |
| config | High | Standard |
| migration | Critical | CRITICAL_SITE approval |

---

## Usage

Change detection runs automatically during deployment. To preview changes without deploying:

```bash
./scripts/deploy/asdev-deploy.sh --check <site-name>
```

This outputs the change manifest without executing any deployment actions.
