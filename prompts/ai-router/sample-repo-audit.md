# Sample AI Router Task — Repo Audit

Task class: `repo-audit`

Goal:
Plan a high-context repository audit. The default provider is MiMo because it can handle long context, but this sample must only produce a routing plan unless explicitly executed.

Example task:
Audit ASDEV AI Gateway files for policy consistency:
- docs/governance/ASDEV_AI_GATEWAY_POLICY.md
- docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md
- scripts/ai-router/provider-health.sh
- scripts/ai-router/run-task.sh

Rules:
- Do not call production systems.
- Do not print secrets.
- Do not deploy.
- Do not SSH.
- Do not mark MiMo available unless command/access is verified on `LOCAL_PC`.

Expected provider:
MiMo
