# Metrics Strategy

## Golden signals (per site)

| Metric | Source |
|--------|--------|
| up (ready 2xx) | check-prod-app-layer / public HTTP after edge |
| latency_ms | stability sample |
| deploy_info | release.meta / check-deploy-status |
| backup_age_h | check-backup-freshness |
| host_disk_ratio | check-disk-local / automation-health |
| queue_depth | control-plane queue.json |

## Export (future)

Write Prometheus textfile or JSON under `control-plane/health/` via approved timers only.

## Anti-goals

- No SaaS required for foundation  
- No high-cardinality labels with secrets/IPs  
