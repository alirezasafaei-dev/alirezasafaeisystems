# Site rollback

Platform model: **symlink-only** to previous release, then healthcheck.

```bash
bash scripts/deploy/asdev-rollback.sh --site <id> --environment production
```

First production deploy may have empty `previous_release` — recovery is redeploy same pin or emergency stop.

Document site-specific data restore steps here when DB is enabled.
