# VPS Deploy Preparation Report (20260616T153142Z)

- Environment: production
- Release ID: 20260616T153142Z-1184fdc
- Commit: 1184fdc
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260616T153142Z-1184fdc/my-portfolio-production-20260616T153142Z-1184fdc.tar.gz
- SHA256 file: artifacts/releases/production/20260616T153142Z-1184fdc/my-portfolio-production-20260616T153142Z-1184fdc.tar.gz.sha256
- Manifest: artifacts/releases/production/20260616T153142Z-1184fdc/manifest.txt
- Artifact size (bytes): 78637231

## Gate Status
- verify: pass
- smoke: pass
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: pass

## Gate Logs
- verify: artifacts/releases/production/20260616T153142Z-1184fdc/logs/verify.log
- smoke: artifacts/releases/production/20260616T153142Z-1184fdc/logs/smoke.log
- ownership: artifacts/releases/production/20260616T153142Z-1184fdc/logs/ownership.log
- nginx contract: artifacts/releases/production/20260616T153142Z-1184fdc/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260616T153142Z-1184fdc/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260616T153142Z-1184fdc/my-portfolio-production-20260616T153142Z-1184fdc.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260616T153142Z-1184fdc && mkdir -p /tmp/release-20260616T153142Z-1184fdc && tar -xzf /tmp/my-portfolio-production-20260616T153142Z-1184fdc.tar.gz -C /tmp/release-20260616T153142Z-1184fdc'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260616T153142Z-1184fdc && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260616T153142Z-1184fdc && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260616T153142Z-1184fdc'
```
