# Sample AI Router Task — Code Patch

Task class: `code-patch`

Goal:
Use OpenCode as the default implementation provider for a harmless local-only patch task.

Example task:
Review `scripts/ai-router/provider-health.sh` and `scripts/ai-router/run-task.sh` for shell syntax errors, missing safety checks, and report-path consistency. Do not execute external providers.

Rules:
- Do not call production systems.
- Do not print secrets.
- Do not commit `.env`.
- Do not deploy.
- Do not SSH.

Expected provider:
OpenCode
