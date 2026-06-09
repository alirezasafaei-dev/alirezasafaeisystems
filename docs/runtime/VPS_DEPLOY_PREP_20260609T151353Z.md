# VPS Deploy Preparation Report (20260609T151353Z)

- Environment: production
- Release ID: 20260609T151353Z-0534bf8
- Commit: 0534bf8
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260609T151353Z-0534bf8/my-portfolio-production-20260609T151353Z-0534bf8.tar.gz
- SHA256 file: artifacts/releases/production/20260609T151353Z-0534bf8/my-portfolio-production-20260609T151353Z-0534bf8.tar.gz.sha256
- Manifest: artifacts/releases/production/20260609T151353Z-0534bf8/manifest.txt
- Artifact size (bytes): 78706407

## Gate Status
- verify: pass
- smoke: fail
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: fail

## Gate Logs
- verify: artifacts/releases/production/20260609T151353Z-0534bf8/logs/verify.log
- smoke: artifacts/releases/production/20260609T151353Z-0534bf8/logs/smoke.log
- ownership: artifacts/releases/production/20260609T151353Z-0534bf8/logs/ownership.log
- nginx contract: artifacts/releases/production/20260609T151353Z-0534bf8/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260609T151353Z-0534bf8/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260609T151353Z-0534bf8/my-portfolio-production-20260609T151353Z-0534bf8.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260609T151353Z-0534bf8 && mkdir -p /tmp/release-20260609T151353Z-0534bf8 && tar -xzf /tmp/my-portfolio-production-20260609T151353Z-0534bf8.tar.gz -C /tmp/release-20260609T151353Z-0534bf8'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260609T151353Z-0534bf8 && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260609T151353Z-0534bf8 && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260609T151353Z-0534bf8'
```
