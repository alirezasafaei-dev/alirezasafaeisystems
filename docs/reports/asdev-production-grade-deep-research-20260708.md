# ASDEV Production-Grade Deep Research Report

**Date:** 2026-07-08  
**Scope:** ASDEV automation, GitHub governance, agent operations, deployment platform, security, observability, and roadmap.  
**Decision:** GitHub is the single source of truth. OWNER_PC is a working copy. AUTOMATION_HOST is an executor. IRAN_PROD is runtime only. CRITICAL_SITE is the first protected production target.

---

## 1. Executive recommendation

The smallest architecture that is still production-grade for ASDEV is:

```text
GitHub = source of truth
OWNER_PC = working copy and private recovery workstation
AUTOMATION_HOST = controlled executor/orchestrator
IRAN_PROD = runtime host only
CRITICAL_SITE = first protected production target
```

Do not introduce Kubernetes, Argo CD, Flux, Drone, or Woodpecker yet as the primary control plane. They are useful tools, but for the current ASDEV topology they add operational burden before the basic production contract is stable.

The recommended near-term model is:

1. GitHub repository governance.
2. Agent memory and handoff stored as safe markdown in GitHub.
3. One registry-driven deploy engine.
4. Capistrano-style releases: `releases/`, `shared/`, `current`.
5. GitHub Actions as the main CI/control plane.
6. AUTOMATION_HOST used only for approved deploy/ops jobs.
7. Ansible later for host convergence and drift control.
8. Prometheus/Blackbox/Node Exporter/Loki/Sentry/OpenTelemetry as the observability path.
9. Restic remains the backup/restore verification tool, but backup does not block current platform foundation work by owner decision.

---

## 2. GitHub governance and API safety

### 2.1 GitHub API and automation limits

Automation must avoid high-frequency polling and excessive mutation. GitHub has both primary and secondary rate limits. The platform should use event-driven execution where possible, batch work, avoid tight loops, and serialize mutating operations.

ASDEV policy:

- Prefer webhook/event-driven operation over polling.
- Use one queue for agent writes to GitHub.
- Avoid many rapid PR/comment/issue mutations.
- Use exponential backoff when limited.
- Keep agent PRs focused and reviewable.
- Do not let agents repeatedly open/close/update PRs in a loop.
- Do not spam Issue comments as the primary state store.
- Keep durable state in versioned files under `docs/automation/` and `docs/roadmaps/`.

### 2.2 GitHub Actions control plane

GitHub Actions should remain the control plane for now because it integrates naturally with branch protection, PR checks, reusable workflows, environments, concurrency, CODEOWNERS, and repository governance.

Required policies:

- Default workflow permissions should be read-only.
- Elevate permissions only per job when required.
- Pin third-party actions by full commit SHA where possible.
- Protect `.github/workflows/` with CODEOWNERS.
- Use concurrency groups per site and environment.
- Use environment protection for production deploys.
- Use self-hosted runner only for approved deploy/ops jobs.
- Run PR/test jobs on safer generic runners where possible.

### 2.3 Source of truth rule

GitHub must contain:

- code
- deployment standards
- registry
- runbooks
- roadmaps
- agent memory
- handoff protocol
- current task queue
- validation rules

OWNER_PC, AUTOMATION_HOST, and IRAN_PROD must not become undocumented planning sources.

---

## 3. Agent operating model

Agents must not become the control plane. They should operate behind strict contracts:

```text
Input: roadmap/task file + runbook + approval policy
Output: branch + PR + validation report + handoff note
State: safe markdown in GitHub
Execution: approved scripts only
```

Required files:

- `AGENTS.md`
- `docs/automation/ASDEV_SOURCE_OF_TRUTH.md`
- `docs/automation/AGENT_MEMORY.md`
- `docs/automation/AGENT_HANDOFF_PROTOCOL.md`
- `docs/automation/AGENT_OPERATING_RULES.md`
- `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`
- `docs/roadmaps/TODAY.md`
- `docs/roadmaps/NEXT_7_DAYS.md`
- `docs/roadmaps/NEXT_30_DAYS.md`
- `docs/roadmaps/NEXT_90_DAYS.md`

Agent handoff must include:

- what changed
- where it changed
- why it changed
- validation commands
- remaining risk
- next action
- approval phrase needed, if any

Agents must not store raw runtime credentials or local-only state in GitHub memory.

---

## 4. Deployment architecture

### 4.1 Recommended deployment pattern

Use one unified deploy engine for all sites. No site-specific hand-written deployment paths unless the site registry defines the difference.

Per-site production layout:

```text
/srv/asdev/sites/<site>/
├── releases/
├── shared/
├── current -> releases/<active-release>
├── logs/
└── metadata/
```

Principles:

- Never edit `current` directly.
- Build or sync into a new release.
- Run preflight before release creation.
- Run healthcheck before activation where possible.
- Switch `current` atomically after checks.
- Roll back by switching to a previous known-good release.
- Keep metadata for every release.
- Keep garbage collection quarantine-first.

### 4.2 Registry schema

The deploy registry must be the contract between docs and scripts. The parser must match the schema exactly.

Required columns:

```text
site_id
display_name
priority
protected
repo_path
artifact_path
prod_base
staging_base
shared_path
healthcheck_url_alias
healthcheck_path
runtime
process_names
build_command
start_command
env_file_alias
deploy_strategy
rollback_strategy
```

Rules:

- `protected=true` for CRITICAL_SITE.
- Unknown sites fail closed.
- No live credential values.
- No raw infrastructure identifiers.
- Use placeholders and aliases only.
- Scripts must validate column count before use.

### 4.3 Smart deploy behavior

Small changes should not always trigger full rebuild/reinstall. Change detection should classify impact:

| Change type | Action |
|---|---|
| docs only | no deploy |
| static public assets | targeted asset update or lightweight release |
| dependency manifests/lockfiles | install dependencies |
| app source | build new release |
| config templates | manual review |
| schema/migration | block for separate approval |

Change detection must use an explicit base/head range, not just `HEAD~1..HEAD`.

---

## 5. Protection model for CRITICAL_SITE

CRITICAL_SITE must be protected by policy and tooling.

Protection scripts should be guard/check-only. They must not implement deploy, stop, restart, removal, DB changes, or symlink switching. The only approved path for changes to CRITICAL_SITE is the unified deploy engine.

Protection checks should detect:

- operations targeting CRITICAL_SITE paths
- deployment attempts outside the deploy engine
- direct symlink switching
- runtime service manipulation outside approval gates
- quarantine attempts against CRITICAL_SITE
- registry drift where CRITICAL_SITE is not protected

---

## 6. Quarantine model for non-critical sites

The safe model is:

```text
inventory -> plan -> allowlist -> dry-run -> approved quarantine -> recovery manifest -> retention -> optional delete later
```

Rules:

- No direct deletion in the first pass.
- Inventory is read-only.
- Unknown ownership is blocked.
- CRITICAL_SITE is never included.
- Quarantine must require an allowlist generated from inventory.
- Live execution must require explicit approval.
- Permanent deletion is a later, separate procedure.

---

## 7. Observability baseline

Recommended baseline:

- Prometheus for metrics.
- Node Exporter for host metrics.
- Blackbox Exporter for CRITICAL_SITE availability probes.
- Alertmanager for routing alerts.
- Loki for logs.
- Sentry for application errors and release health.
- OpenTelemetry as the future instrumentation standard.

Initial ASDEV SLOs:

| Area | SLI | Suggested target |
|---|---|---|
| CRITICAL_SITE availability | external probe success | 99.9% monthly |
| deploy success | successful production deploys | >= 95% over 30 days |
| rollback readiness | time to healthy rollback | <= 10 minutes |
| backup freshness | latest verified snapshot age | <= 24 hours |
| restore confidence | isolated restore drill | monthly success |
| disk safety | free space on runtime/executor | >= 20% |

---

## 8. Security and supply chain

Near-term security controls:

- CODEOWNERS for deployment, workflows, and ops scripts.
- Branch protection on main.
- PR review before merge.
- Required checks for CI router and script validation.
- Default read-only workflow token permissions.
- Secret scanning/guard scripts in repo.
- Dependabot or Renovate for dependency updates.
- Trivy/Syft for vulnerability and SBOM checks where practical.
- SOPS + age for limited encrypted configuration if needed.
- Infisical or Bitwarden Secrets Manager later for central secrets management.

Mature-but-later options:

- Argo CD / Flux after Kubernetes adoption.
- Drone/Woodpecker only if GitHub Actions becomes insufficient.
- Sigstore/Cosign/artifact attestations after artifact workflow is stable.
- Ansible for host convergence after deploy contract is stable.

---

## 9. Recommended 30/90/180 day roadmap

### First 30 days

- Standardize local root to `/home/dev13/ASDEV`.
- Merge source-of-truth governance.
- Freeze deploy registry schema.
- Fix and validate deploy engine.
- Protect CRITICAL_SITE.
- Add agent memory and handoff protocol.
- Add roadmaps and queue structure.
- Add CI router and script validation.
- Prepare CRITICAL_SITE staging deploy.
- Add monitoring templates.

### First 90 days

- Implement baseline observability.
- Add Ansible host convergence for IRAN_PROD and AUTOMATION_HOST.
- Add dependency and supply-chain scanning.
- Add deployment reports and release dashboard.
- Complete non-critical site inventory and quarantine plan.
- Move each site into unified deploy registry one by one.
- Add more robust secret management.

### First 180 days

- Evaluate isolated runners or ephemeral deploy runners.
- Evaluate Kubernetes only if the site count and operational complexity justify it.
- Add progressive delivery if traffic and architecture justify canary/blue-green.
- Add release attestations and SBOM publishing.
- Build internal ASDEV dashboard for roadmaps, deploys, incidents, and agent handoffs.

---

## 10. Immediate implementation order

1. Review and fix PR #71.
2. Add this research report to the PR.
3. Merge governance/docs only after scripts are safe.
4. Do not execute production deploy from PR #71 yet.
5. Fix deploy healthcheck semantics.
6. Add missing quarantine execution script only if it remains dry-run/default-safe and allowlist-based.
7. Add CODEOWNERS and CI router in a follow-up PR.
8. Run staging preflight for CRITICAL_SITE only after script review.

---

## 11. Source list

Official and high-quality sources reviewed:

- GitHub Actions reusable workflows: https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
- GitHub Actions concurrency: https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs
- GitHub environments: https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment
- GitHub branch protection: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- GitHub CODEOWNERS: https://docs.github.com/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- GitHub secure Actions usage: https://docs.github.com/en/actions/reference/security/secure-use
- GitHub REST API rate limits: https://docs.github.com/rest/using-the-rest-api/rate-limits-for-the-rest-api
- GitHub REST API best practices: https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api
- GitHub webhook best practices: https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks
- Argo CD: https://argo-cd.readthedocs.io/
- Flux CD: https://fluxcd.io/flux/
- Drone CI: https://docs.drone.io/
- Woodpecker CI: https://woodpecker-ci.org/
- Ansible: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html
- Capistrano release structure: https://capistranorb.com/documentation/getting-started/structure/
- Prometheus Node Exporter guide: https://prometheus.io/docs/guides/node-exporter/
- Prometheus Alertmanager: https://prometheus.io/docs/alerting/latest/configuration/
- Blackbox Exporter: https://github.com/prometheus/blackbox_exporter
- Grafana Loki: https://grafana.com/docs/loki/latest/
- Sentry releases: https://docs.sentry.io/product/releases/
- OpenTelemetry: https://opentelemetry.io/docs/
- restic repository checks: https://restic.readthedocs.io/en/latest/045_working_with_repos.html
- restic restore: https://restic.readthedocs.io/en/latest/050_restore.html
- BorgBackup: https://borgbackup.readthedocs.io/
- Infisical: https://infisical.com/docs/documentation/getting-started/introduction
- Bitwarden Secrets Manager: https://bitwarden.com/help/secrets-manager-overview/
- SOPS: https://getsops.io/
- Syft: https://github.com/anchore/syft
- Trivy: https://github.com/aquasecurity/trivy
- LangGraph: https://docs.langchain.com/oss/python/langgraph/overview
- SWE-agent paper: https://arxiv.org/abs/2405.15793
- Google SRE SLO chapter: https://sre.google/sre-book/service-level-objectives/
