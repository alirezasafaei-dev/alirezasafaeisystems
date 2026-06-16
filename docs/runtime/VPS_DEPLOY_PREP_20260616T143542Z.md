# VPS Deploy Preparation Report (20260616T143542Z)

- Environment: production
- Release ID: 20260616T143542Z-ac256ff
- Commit: ac256ff
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/20260616T143542Z-ac256ff/my-portfolio-production-20260616T143542Z-ac256ff.tar.gz
- SHA256 file: artifacts/releases/production/20260616T143542Z-ac256ff/my-portfolio-production-20260616T143542Z-ac256ff.tar.gz.sha256
- Manifest: artifacts/releases/production/20260616T143542Z-ac256ff/manifest.txt
- Artifact size (bytes): 78636162

## Gate Status
- verify: pass
- smoke: fail
- ownership: pass
- nginx contract: pass
- hosting sync: pass
- overall: fail

## Gate Logs
- verify: artifacts/releases/production/20260616T143542Z-ac256ff/logs/verify.log
- smoke: artifacts/releases/production/20260616T143542Z-ac256ff/logs/smoke.log
- ownership: artifacts/releases/production/20260616T143542Z-ac256ff/logs/ownership.log
- nginx contract: artifacts/releases/production/20260616T143542Z-ac256ff/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/20260616T143542Z-ac256ff/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/20260616T143542Z-ac256ff/my-portfolio-production-20260616T143542Z-ac256ff.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-20260616T143542Z-ac256ff && mkdir -p /tmp/release-20260616T143542Z-ac256ff && tar -xzf /tmp/my-portfolio-production-20260616T143542Z-ac256ff.tar.gz -C /tmp/release-20260616T143542Z-ac256ff'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-20260616T143542Z-ac256ff && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-20260616T143542Z-ac256ff && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-20260616T143542Z-ac256ff'
```
