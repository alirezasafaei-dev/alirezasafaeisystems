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

```
site_name	status	criticality	deploy_path	backup_path	healthcheck_url	approval_required
auditsystems	active	normal	/srv/asdev/sites/auditsystems/	/srv/asdev/backups/auditsystems/	https://auditsystems.ir	yes
persiantoolbox	critical	critical	/srv/asdev/sites/persiantoolbox/	/srv/asdev/backups/persiantoolbox/	https://persiantoolbox.ir	yes
```

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
- Keep last 5 releases by default
- Critical sites: Keep all releases
- Non-critical sites: Quarantine after 7 days

### 10.2 Backup Retention
- Keep backups for 30 days
- Critical sites: Keep backups for 90 days

### 10.3 Quarantine Period
- 7 days for non-critical sites
- No quarantine for critical sites