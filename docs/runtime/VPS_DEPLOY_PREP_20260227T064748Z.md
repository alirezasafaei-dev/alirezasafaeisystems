# VPS Deploy Preparation Report (20260227T064748Z)

- Environment: production
- Release ID: 20260227T064748Z-7da9147
- Commit: 7da9147
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260227T064748Z-7da9147/my-portfolio-production-20260227T064748Z-7da9147.tar.gz
- SHA256 file: artifacts/releases/production/20260227T064748Z-7da9147/my-portfolio-production-20260227T064748Z-7da9147.tar.gz.sha256
- Manifest: artifacts/releases/production/20260227T064748Z-7da9147/manifest.txt
- Artifact size (bytes): 10785911

## Gate Status
- verify: pass
- smoke: pass
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: pass

## Gate Logs
- verify: artifacts/releases/production/20260227T064748Z-7da9147/logs/verify.log
- smoke: artifacts/releases/production/20260227T064748Z-7da9147/logs/smoke.log
- ownership: artifacts/releases/production/20260227T064748Z-7da9147/logs/ownership.log
- nginx contract: artifacts/releases/production/20260227T064748Z-7da9147/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260227T064748Z-7da9147/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260227T064748Z-7da9147/my-portfolio-production-20260227T064748Z-7da9147.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260227T064748Z-7da9147 && mkdir -p /tmp/release-20260227T064748Z-7da9147 && tar -xzf /tmp/my-portfolio-production-20260227T064748Z-7da9147.tar.gz -C /tmp/release-20260227T064748Z-7da9147'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260227T064748Z-7da9147 && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260227T064748Z-7da9147 && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260227T064748Z-7da9147'
```
