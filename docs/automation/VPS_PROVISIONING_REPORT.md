# VPS Provisioning Report — Continued

**Status:** Partially complete — GitHub auth pending
**Date:** 2026-07-07

## Completed

- SSH key login works
- Base packages installed
- Node.js, npm, pnpm, and GitHub CLI installed
- UFW and fail2ban configured
- SSH hardening applied

## Current Blocker

Owner action is still required for GitHub CLI authentication on the server. No token, password, IP address, or secret is stored in this document.

## Next Steps

1. Configure passwordless sudo for the `asdev` user and validate the sudoers file.
2. Authenticate GitHub CLI interactively on the server.
3. Clone `alirezasafaeisystems` and `auditsystems` under `/opt/asdev`.
4. Install dependencies in both repos.
5. Copy systemd user units, reload systemd, and enable linger.
6. Run healthcheck and dry-run before enabling the recurring timer.
7. Run one safe real job and confirm the report appears in Issue #45.
8. Cut over only after VPS validation passes.

## Safety

- PersianToolbox remains protected and must not be edited or cloned for write tasks.
- No secrets, IPs, passwords, or tokens are documented here.
- Keep the local timer as fallback until VPS healthcheck, dry-run, and one safe real job pass.
