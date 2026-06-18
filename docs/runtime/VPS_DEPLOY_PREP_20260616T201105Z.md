# VPS Deploy Preparation Report (20260616T201105Z)

- Environment: production
- Release ID: 20260616T201105Z-3032e25
- Commit: 3032e25
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260616T201105Z-3032e25/my-portfolio-production-20260616T201105Z-3032e25.tar.gz
- SHA256 file: artifacts/releases/production/20260616T201105Z-3032e25/my-portfolio-production-20260616T201105Z-3032e25.tar.gz.sha256
- Manifest: artifacts/releases/production/20260616T201105Z-3032e25/manifest.txt
- Artifact size (bytes): 78641695

## Gate Status
- verify: pass
- smoke: fail
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: fail

## Gate Logs
- verify: artifacts/releases/production/20260616T201105Z-3032e25/logs/verify.log
- smoke: artifacts/releases/production/20260616T201105Z-3032e25/logs/smoke.log
- ownership: artifacts/releases/production/20260616T201105Z-3032e25/logs/ownership.log
- nginx contract: artifacts/releases/production/20260616T201105Z-3032e25/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260616T201105Z-3032e25/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260616T201105Z-3032e25/my-portfolio-production-20260616T201105Z-3032e25.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260616T201105Z-3032e25 && mkdir -p /tmp/release-20260616T201105Z-3032e25 && tar -xzf /tmp/my-portfolio-production-20260616T201105Z-3032e25.tar.gz -C /tmp/release-20260616T201105Z-3032e25'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260616T201105Z-3032e25 && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260616T201105Z-3032e25 && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260616T201105Z-3032e25'
```
