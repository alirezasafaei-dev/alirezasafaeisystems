# Sample AI Router Task — Provider Health

Task class: `provider-health`

Goal:
Run the local provider health scaffold and report which ASDEV AI providers are available on `LOCAL_PC`.

Rules:
- Do not call external APIs.
- Do not print secrets.
- Do not deploy.
- Do not SSH.

Expected command:

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh
```
