# Site monitoring

Default probes:

```bash
# On IRAN_PROD after production app-layer:
bash scripts/monitoring/check-prod-app-layer.sh --port <prod_port>
bash scripts/monitoring/check-deploy-status.sh --site-root /srv/asdev/sites/<id> --port <prod_port>

# After public edge:
bash scripts/monitoring/check-critical-site-http.sh --url https://<domain>
```

See `docs/ops/monitoring-standard.md`.
