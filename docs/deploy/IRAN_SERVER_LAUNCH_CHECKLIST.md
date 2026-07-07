# Iran Server Launch Checklist

**Status:** Ready for execution
**Date:** 2026-07-07
**Target:** https://audit.alirezasafaeisystems.ir/

## 1. Git State

- [ ] main branch clean
- [ ] PRs merged or deferred
- [ ] Release commit identified
- [ ] No uncommitted changes

## 2. Build

- [ ] pnpm install (production deps)
- [ ] pnpm build succeeds
- [ ] pnpm typecheck passes
- [ ] pnpm test passes (589/589)
- [ ] No new type errors

## 3. Config

- [ ] production.env present on server
- [ ] No secrets in repo
- [ ] DATABASE_URL configured
- [ ] SESSION_SECRET configured
- [ ] NEXT_PUBLIC_SITE_URL configured
- [ ] Domain DNS pointing to server
- [ ] Nginx config checked

## 4. Database

- [ ] Backup taken before deploy
- [ ] Migration plan documented
- [ ] No destructive migration
- [ ] BillingEvent model present (PR #22 merged)
- [ ] Rollback path exists

## 5. Server

- [ ] Disk space > 5GB free
- [ ] Memory > 1GB free
- [ ] Node.js version compatible
- [ ] pnpm version compatible
- [ ] PM2 running
- [ ] Nginx running
- [ ] Firewall configured
- [ ] SSL valid
- [ ] Logs accessible

## 6. Health

- [ ] Local: pnpm build passes
- [ ] Server: /api/ready returns 200
- [ ] Server: homepage loads
- [ ] Server: login page loads
- [ ] Server: dashboard loads
- [ ] Server: audit form works
- [ ] Server: report generation works

## 7. Rollback

- [ ] Previous release identified
- [ ] Rollback command: cd /var/www/asdev-audit-ir/releases/production && ls (find previous)
- [ ] Rollback: symlink to previous release + pm2 restart
- [ ] Database rollback: restore from backup
- [ ] Service restart: pm2 restart asdev-audit-ir-production-web

## Deploy Commands

```bash
# From local machine
cd sites/live/auditsystems
pnpm run vps:deploy

# Or manual
bash scripts/vps-deploy.sh deploy production

# Verify
bash scripts/smoke-public-routes.sh
```

## Post-Deploy

1. Run smoke tests
2. Check PM2 status
3. Check nginx status
4. Check SSL
5. Monitor logs for 10 minutes
6. Report to Issue #45
