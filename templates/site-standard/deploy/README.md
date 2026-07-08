# Deploy notes (per site)

Fill for each site:

| Field | Value |
|-------|-------|
| site id | |
| prod_port | |
| staging_port | |
| health paths | `/api/ready`, `/api/health` |
| build_command_id | |
| start_command_id | |
| approval phrases | staging / production |

Commands (platform root):

```bash
bash scripts/deploy/asdev-preflight.sh --site <id> --environment staging --commit <sha> --dry-run
bash scripts/deploy/asdev-deploy.sh --site <id> --environment staging --commit <sha> --dry-run
```

Never put secrets here.
