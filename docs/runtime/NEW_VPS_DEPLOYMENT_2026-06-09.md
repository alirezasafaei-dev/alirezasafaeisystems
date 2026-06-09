# New VPS Deployment Record

Date: 2026-06-09

## Project Boundary
- Local project: `sites/live/alirezasafaeisystems`
- Canonical public URL: `https://alirezasafaeisystems.ir/`
- Old locale URL behavior: `/fa` redirects to `/`
- Server release path: `/var/www/my-portfolio/releases/production/20260609T171500Z-no-fa-prefix`
- Shared env path: `/var/www/my-portfolio/shared/env/production.env`
- PM2 process: `my-portfolio-production`
- Listener: `127.0.0.1:3002`

## Current Production State
- The project is deployed independently on the new VPS.
- The Persian default is served without the `/fa` suffix.
- Nginx terminates TLS for `alirezasafaeisystems.ir` and `www.alirezasafaeisystems.ir`.

## Validation
| Check | Last recorded result |
|---|---|
| `https://alirezasafaeisystems.ir/` | `200` |
| `https://alirezasafaeisystems.ir/api/ready` | `200` |

## Safe Operational Commands
- Process list: `pm2 list`
- Process details: `pm2 show my-portfolio-production`
- Local readiness on VPS: `curl -fsS http://127.0.0.1:3002/api/ready`
- Public readiness: `curl -fsS https://alirezasafaeisystems.ir/api/ready`
- Nginx config test: `sudo nginx -t`

## Deployment Notes
- Release identifier: `20260609T171500Z-no-fa-prefix`
- Keep the portfolio deployment separate from `persiantoolbox` and `auditsystems`.
- Use current project code and docs as the source of truth; do not deploy from old Codex snapshots.

## Security Notes
- Do not print or commit `/var/www/my-portfolio/shared/env/production.env`.
- Do not document secret values, database URLs, API tokens, or admin credentials.
