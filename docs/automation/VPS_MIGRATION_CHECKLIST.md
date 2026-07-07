# VPS Migration Checklist

**Status:** Ready to execute
**Date:** 2026-07-07

## Pre-Migration

- [ ] 1. Buy VPS (Ubuntu 24.04, 4 vCPU / 8GB RAM / 80GB NVMe)
- [ ] 2. Choose location (Germany, Netherlands, or France)
- [ ] 3. Add SSH key during provisioning
- [ ] 4. Disable password login after key confirmed
- [ ] 5. Create `asdev` user

## Bootstrap

- [ ] 6. SSH into VPS as root
- [ ] 7. Run: `bash scripts/vps/bootstrap-asdev-agent.sh`
- [ ] 8. Verify: `ufw status`, `node --version`, `pnpm --version`, `gh --version`

## Authentication

- [ ] 9. `su - asdev`
- [ ] 10. `gh auth login` (with token from .env)
- [ ] 11. Verify: `gh auth status`

## Repo Setup

- [ ] 12. Run: `bash scripts/vps/sync-repos-to-vps.sh asdev@vps-ip`
- [ ] 13. Verify: `ls /opt/asdev/alirezasafaeisystems`
- [ ] 14. Verify: `ls /opt/asdev/auditsystems`

## Systemd

- [ ] 15. Copy units: `cp ops/systemd/vps/*.service ops/systemd/vps/*.timer ~/.config/systemd/user/`
- [ ] 16. `systemctl --user daemon-reload`
- [ ] 17. `loginctl enable-linger asdev`
- [ ] 18. `systemctl --user enable --now asdev-agent-loop.timer`

## Validation

- [ ] 19. Run healthcheck: `./scripts/agent-command-center/agent-healthcheck.sh`
- [ ] 20. Run dry-run: `./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1 --dry-run`
- [ ] 21. Run one safe real job: `./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 1`
- [ ] 22. Confirm Issue #45 report from VPS

## Cutover

- [ ] 23. Stop local timer: `systemctl --user stop asdev-agent-loop.timer`
- [ ] 24. Enable VPS timer (already enabled in step 18)
- [ ] 25. Keep local machine as fallback for 48 hours
- [ ] 26. Monitor VPS for 24 hours

## Post-Migration

- [ ] 27. Set backup/snapshot schedule
- [ ] 28. Document VPS IP/provider/location
- [ ] 29. Set up Telegram notifications (optional)
- [ ] 30. Verify reboot survival
