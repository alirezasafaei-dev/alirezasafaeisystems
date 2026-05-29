# VPS Deploy Preparation Report (20260529T121703Z)

- Environment: production
- Release ID: quick-fix-20260529T121703Z-05a35b5
- Commit: 05a35b5
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/my-portfolio-production-quick-fix-20260529T121703Z-05a35b5.tar.gz
- SHA256 file: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/my-portfolio-production-quick-fix-20260529T121703Z-05a35b5.tar.gz.sha256
- Manifest: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/manifest.txt
- Artifact size (bytes): 74279248

## Gate Status
- verify: skipped
- smoke: skipped
- ownership: skipped
- nginx contract: skipped
- hosting sync: skipped
- overall: pass

## Gate Logs
- verify: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/logs/verify.log
- smoke: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/logs/smoke.log
- ownership: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/logs/ownership.log
- nginx contract: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/quick-fix-20260529T121703Z-05a35b5/my-portfolio-production-quick-fix-20260529T121703Z-05a35b5.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-quick-fix-20260529T121703Z-05a35b5 && mkdir -p /tmp/release-quick-fix-20260529T121703Z-05a35b5 && tar -xzf /tmp/my-portfolio-production-quick-fix-20260529T121703Z-05a35b5.tar.gz -C /tmp/release-quick-fix-20260529T121703Z-05a35b5'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-quick-fix-20260529T121703Z-05a35b5 && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-quick-fix-20260529T121703Z-05a35b5 && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-quick-fix-20260529T121703Z-05a35b5'
```
