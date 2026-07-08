# Uptime Strategy

## Layers

1. **Loopback** truth: `127.0.0.1:<prod_port>/api/ready` on IRAN  
2. **Deploy** truth: pid + current symlink + release.meta  
3. **Public** truth: HTTPS domain (only after public edge)  

## Probes ready now

- `check-prod-app-layer.sh`  
- `check-prod-stability-sample.sh`  
- `check-deploy-status.sh`  
- `check-critical-site-http.sh` (edge-dependent)  

## SLO intent

See `docs/SLO_AVAILABILITY_BUDGET.md` when product public.  
App-layer only period: measure loopback availability, not public.
