# VPS Deploy Preparation Report (20260616T144827Z)

- Environment: production
- Release ID: 20260616T144827Z-0209b18
- Commit: 0209b18
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260616T144827Z-0209b18/my-portfolio-production-20260616T144827Z-0209b18.tar.gz
- SHA256 file: artifacts/releases/production/20260616T144827Z-0209b18/my-portfolio-production-20260616T144827Z-0209b18.tar.gz.sha256
- Manifest: artifacts/releases/production/20260616T144827Z-0209b18/manifest.txt
- Artifact size (bytes): 78636428

## Gate Status
- verify: pass
- smoke: fail
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: fail

## Gate Logs
- verify: artifacts/releases/production/20260616T144827Z-0209b18/logs/verify.log
- smoke: artifacts/releases/production/20260616T144827Z-0209b18/logs/smoke.log
- ownership: artifacts/releases/production/20260616T144827Z-0209b18/logs/ownership.log
- nginx contract: artifacts/releases/production/20260616T144827Z-0209b18/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260616T144827Z-0209b18/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260616T144827Z-0209b18/my-portfolio-production-20260616T144827Z-0209b18.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260616T144827Z-0209b18 && mkdir -p /tmp/release-20260616T144827Z-0209b18 && tar -xzf /tmp/my-portfolio-production-20260616T144827Z-0209b18.tar.gz -C /tmp/release-20260616T144827Z-0209b18'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260616T144827Z-0209b18 && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260616T144827Z-0209b18 && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260616T144827Z-0209b18'
```
