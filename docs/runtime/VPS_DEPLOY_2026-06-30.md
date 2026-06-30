# VPS Deploy Record

Date: 2026-06-30

## Summary
- Production deploy was executed from the project-local entrypoint: `bash scripts/vps-deploy.sh deploy production`
- Release path: `/var/www/my-portfolio/releases/production/20260630T155740Z-root`
- PM2 process: `my-portfolio-production`
- Local readiness: `http://127.0.0.1:3002/api/ready`
- Public readiness: `https://alirezasafaeisystems.ir/api/ready`

## Isolated Runtime Contract
- Base dir: `/var/www/my-portfolio`
- Shared env: `/var/www/my-portfolio/shared/env/production.env`
- Shared logs: `/var/www/my-portfolio/shared/logs/`
- Current symlink: `/var/www/my-portfolio/current/production`
- Production port: `127.0.0.1:3002`
- Staging port reservation: `127.0.0.1:3003`

## Notes
- The root workspace provides shared orchestration and status only.
- Production deploys must continue to start from this repository via `scripts/vps-deploy.sh`.
- Keep this app isolated from `persiantoolbox` and `auditsystems` at the PM2, env, release, and Nginx layers.
