# Standard Deploy Layout

**Version:** 1.0
**Last Updated:** 2026-07-08
**Scope:** All ASDEV site deployments

---

## 1. Overview

This document defines the standard directory structure for ASDEV site deployments. All sites must follow this layout for consistency and tooling compatibility.

---

## 2. Deploy Path Structure

```
/srv/asdev/sites/<site-name>/
├── current -> releases/<version>      # Symlink to active version
├── releases/
│   ├── <version-1>/
│   │   ├── app/                       # Application code
│   │   ├── config/                    # Configuration files
│   │   ├── public/                    # Public assets
│   │   ├── storage/                   # Storage directory
│   │   ├── logs/                      # Application logs
│   │   └── .release-meta              # Release metadata
│   ├── <version-2>/
│   │   └── ...
│   └── ...
├── shared/                            # Shared across versions
│   ├── config/                        # Shared configuration
│   ├── storage/                       # Shared storage
│   ├── logs/                          # Shared logs
│   └── tmp/                           # Temporary files
└── .deploy/                           # Deployment metadata
    ├── registry.tsv                   # Site registry
    ├── deployments.log                # Deployment history
    ├── current-manifest.json          # Current change manifest
    └── rollback-info.json             # Rollback information
```

---

## 3. Directory Descriptions

### 3.1 Root Level
- **current**: Symlink pointing to the active release version
- **releases/**: Contains all release versions
- **shared/**: Shared resources across all versions
- **.deploy/**: Deployment system metadata

### 3.2 Release Structure
Each release contains:
- **app/**: Application source code
- **config/**: Version-specific configuration
- **public/**: Public-facing assets (HTML, CSS, JS, images)
- **storage/**: Application storage (uploads, caches)
- **logs/**: Application log files
- **.release-meta**: Metadata about the release

### 3.3 Shared Structure
Shared resources persist across deployments:
- **config/**: Shared configuration files
- **storage/**: Shared storage (uploads, user data)
- **logs/**: Consolidated log storage
- **tmp/**: Temporary files and caches

---

## 4. Version Numbering

### 4.1 Format
```
YYYYMMDD-HHMMSS-<short-hash>
```

Example: `20260708-125200-a1b2c3d`

### 4.2 Components
- **YYYYMMDD**: Date (YYYY-MM-DD)
- **HHMMSS**: Time (HH:MM:SS)
- **short-hash**: 7-character Git commit hash

---

## 5. Backup Structure

```
/srv/asdev/backups/<site-name>/
├── <version>-<timestamp>.tar.gz
├── <version>-<timestamp>.tar.gz.meta
└── ...
```

### 5.1 Backup Naming
```
<version>-<YYYYMMDD-HHMMSS>.tar.gz
```

### 5.2 Backup Metadata
Each backup includes a `.meta` file with:
- Version deployed
- Timestamp
- Deployer identity
- Change manifest

---

## 6. Deploy Metadata Structure

### 6.1 .release-meta
```json
{
  "version": "20260708-125200-a1b2c3d",
  "deployed_at": "2026-07-08T12:52:00Z",
  "deployed_by": "deployer@asdev",
  "git_commit": "a1b2c3d4e5f6g7h8i9j0",
  "git_branch": "main",
  "change_manifest": {
    "docs": ["README.md"],
    "assets": ["public/css/main.css"],
    "deps": ["package.json"],
    "source": ["src/app.ts"],
    "config": [".env"],
    "migration": []
  }
}
```

### 6.2 deployments.log
```
[2026-07-08T12:52:00Z] DEPLOY auditsystems 20260708-125200-a1b2c3d by deployer@asdev
[2026-07-08T12:55:00Z] HEALTH auditsystems 20260708-125200-a1b2c3d PASS
[2026-07-08T13:00:00Z] ROLLBACK auditsystems 20260708-125200-a1b2c3d to 20260707-110000-x9y8z7
```

### 6.3 current-manifest.json
```json
{
  "version": "20260708-125200-a1b2c3d",
  "changes": {
    "docs": ["README.md"],
    "assets": ["public/css/main.css"],
    "deps": ["package.json"],
    "source": ["src/app.ts"],
    "config": [".env"],
    "migration": []
  },
  "impact_level": "medium",
  "requires_approval": false
}
```

### 6.4 rollback-info.json
```json
{
  "current_version": "20260708-125200-a1b2c3d",
  "previous_version": "20260707-110000-x9y8z7",
  "rollback_available": true,
  "rollback_path": "/srv/asdev/backups/auditsystems/20260707-110000-x9y8z7-20260708-125000.tar.gz"
}
```

---

## 7. Site Registry Structure

Location: `deploy/registry.tsv`

Columns (20, tab-separated):
```
site_id  display_name  priority  protected  repo_path  artifact_path  prod_base  staging_base  shared_path  healthcheck_mode  healthcheck_host_alias  healthcheck_port  healthcheck_path  runtime  process_names  build_command_id  start_command_id  env_file_alias  deploy_strategy  rollback_strategy
```

### 7.1 Column Definitions

| # | Column | Description |
|---|--------|-------------|
| 1 | `site_id` | Unique site identifier |
| 2 | `display_name` | Human-readable site name |
| 3 | `priority` | Numeric priority (1=highest) |
| 4 | `protected` | `true` or `false` — CRITICAL_SITE must be `true` |
| 5 | `repo_path` | Path to source repo relative to project root |
| 6 | `artifact_path` | Path to pre-built artifact (fallback if repo not available) |
| 7 | `prod_base` | Production deploy base path |
| 8 | `staging_base` | Staging deploy base path |
| 9 | `shared_path` | Shared resources path (persists across releases) |
| 10 | `healthcheck_mode` | Healthcheck mode: `local-port`, `http`, or `-` (skip) |
| 11 | `healthcheck_host_alias` | Host alias for healthcheck (e.g. `persiantoolbox.example.com`) |
| 12 | `healthcheck_port` | Local port for `local-port` mode healthcheck |
| 13 | `healthcheck_path` | HTTP path for healthcheck (e.g. `/api/ready`) |
| 14 | `runtime` | Runtime type: `node`, `python`, etc. |
| 15 | `process_names` | PM2 process names (pipe-separated for multi-process) |
| 16 | `build_command_id` | Build command ID (see §7.2) |
| 17 | `start_command_id` | Start command ID (see §7.3) |
| 18 | `env_file_alias` | Environment file alias |
| 19 | `deploy_strategy` | Always `symlink` |
| 20 | `rollback_strategy` | Always `symlink` |

### 7.2 Build Command IDs

| ID | Equivalent Command |
|----|-------------------|
| `node-pnpm-build` | `pnpm install --frozen-lockfile && pnpm run build` |
| `node-npm-build` | `npm ci && npm run build` |
| `static-copy` | No build — static copy only |
| `no-build` / `-` / (empty) | No build step |

### 7.3 Start Command IDs

| ID | Equivalent Command |
|----|-------------------|
| `node-standalone` | `node .next/standalone/server.js` |
| `node-nextstart` | `pnpm run start` |
| `python-gunicorn` | `gunicorn app:app` |
| `static-serve` | `npx serve -s .` |
| `no-start` / `-` / (empty) | No start step |

### 7.4 Registry Rules
- `protected` must be `true` or `false` (not "critical" or "normal")
- CRITICAL_SITE (persiantoolbox.ir) must have `protected=true`
- No raw IPs or real secret paths — use aliases and placeholders only
- `process_names` are pipe-separated within a single column
- `deploy_strategy` and `rollback_strategy` are always `symlink`
- Use command IDs (§7.2, §7.3) — never raw shell commands in registry rows

---

## 8. Environment Configuration

### 8.1 Template Location
```
templates/site.deploy.example.env
```

### 8.2 Required Variables
- `SITE_NAME`: Site identifier
- `DEPLOY_PATH`: Deployment directory
- `BACKUP_PATH`: Backup storage directory
- `HEALTHCHECK_URL`: Health check endpoint
- `CRITICALITY`: Site criticality level

---

## 9. File Permissions

### 9.1 Deploy Directory
- Owner: deployer
- Group: deployers
- Permissions: 755

### 9.2 Shared Directory
- Owner: deployer
- Group: deployers
- Permissions: 775

### 9.3 Log Files
- Owner: deployer
- Group: deployers
- Permissions: 644

---

## 10. Cleanup Rules

### 10.1 Release Retention
- Keep last 5 releases by default (configurable via `--keep-releases`)
- Excess releases are quarantined, never deleted directly
- Protected sites: releases are never deleted

### 10.2 Quarantine Period
- Releases older than 7 days (configurable via `--quarantine-days`) are candidates for quarantine
- Quarantine moves releases to `.quarantine/` directory
- Deletion requires explicit `--approve-phrase APPROVE_RELEASE_DELETE`
- Protected site quarantined releases are never deleted

### 10.3 No Destructive Defaults
- `asdev-release-gc.sh` only quarantines by default
- Deletion is impossible unless `APPROVE_RELEASE_DELETE` is passed
- No `--force` flag exists in any script