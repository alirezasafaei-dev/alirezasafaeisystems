# VPS Deploy Preparation Report (20260529T124324Z)

- Environment: production
- Release ID: qualification-quick-fix-20260529T124324Z-18f56ab
- Commit: 18f56ab
- Branch: main
- Worktree state: clean
- Artifact: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/my-portfolio-production-qualification-quick-fix-20260529T124324Z-18f56ab.tar.gz
- SHA256 file: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/my-portfolio-production-qualification-quick-fix-20260529T124324Z-18f56ab.tar.gz.sha256
- Manifest: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/manifest.txt
- Artifact size (bytes): 74288919

## Gate Status
- verify: skipped
- smoke: skipped
- ownership: skipped
- nginx contract: skipped
- hosting sync: skipped
- overall: pass

## Gate Logs
- verify: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/logs/verify.log
- smoke: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/logs/smoke.log
- ownership: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/logs/ownership.log
- nginx contract: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/logs/nginx-contract.log
- hosting sync: artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/logs/hosting-sync.log

## VPS Deploy Commands
```bash
# 1) Upload artifact to VPS
scp artifacts/releases/production/qualification-quick-fix-20260529T124324Z-18f56ab/my-portfolio-production-qualification-quick-fix-20260529T124324Z-18f56ab.tar.gz <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab && mkdir -p /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab && tar -xzf /tmp/my-portfolio-production-qualification-quick-fix-20260529T124324Z-18f56ab.tar.gz -C /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab && bash scripts/vps-preflight.sh --env production --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab && bash ops/deploy/deploy.sh --env production --source-dir /tmp/release-qualification-quick-fix-20260529T124324Z-18f56ab'
```
