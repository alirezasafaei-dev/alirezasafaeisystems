#!/usr/bin/env bash
set -euo pipefail

PRIMARY=""
BACKUP=""
APPROVER=""
COMMANDER=""
PRIMARY_CHANNEL=""
BACKUP_CHANNEL=""
DOC_PATH="docs/ONCALL_ESCALATION.md"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --primary <name> --backup <name> --approver <name> --commander <name> --primary-channel <channel> --backup-channel <channel> [--doc-path <path>]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --primary)
      PRIMARY="${2:-}"
      shift 2
      ;;
    --backup)
      BACKUP="${2:-}"
      shift 2
      ;;
    --approver)
      APPROVER="${2:-}"
      shift 2
      ;;
    --commander)
      COMMANDER="${2:-}"
      shift 2
      ;;
    --primary-channel)
      PRIMARY_CHANNEL="${2:-}"
      shift 2
      ;;
    --backup-channel)
      BACKUP_CHANNEL="${2:-}"
      shift 2
      ;;
    --doc-path)
      DOC_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PRIMARY" || -z "$BACKUP" || -z "$APPROVER" || -z "$COMMANDER" || -z "$PRIMARY_CHANNEL" || -z "$BACKUP_CHANNEL" ]]; then
  usage
  exit 1
fi

cat > "$DOC_PATH" <<DOC
# On-Call and Escalation Ownership

## Purpose
Define who responds to production incidents and how escalation works for \`alirezasafaeisystems\`.

## Roles
- Service: \`alirezasafaeisystems\`
- Primary on-call: \`${PRIMARY}\`
- Backup on-call: \`${BACKUP}\`
- Release approver: \`${APPROVER}\`
- Incident commander (P1/P0): \`${COMMANDER}\`

## Alert Sources
- GitHub Action: \`SLO Monitor\` (\`.github/workflows/slo-monitor.yml\`)
- Health endpoint: \`GET /api/ready\`
- PM2 process health (\`my-portfolio-production\`, \`my-portfolio-staging\`)

## Escalation Policy
1. P2 issue (degraded, no outage): primary on-call responds within 4h.
2. P1 issue (partial outage): primary responds within 30m, backup auto-escalated at +15m.
3. P0 issue (full outage/security risk): immediate escalation to incident commander and release approver.

## Communication Channels
- Primary channel: \`${PRIMARY_CHANNEL}\`
- Backup channel: \`${BACKUP_CHANNEL}\`
- Incident log location: \`docs/runtime/Incidents/\`

## Approval Gates
- Production deploy requires:
- quality gates pass (\`verify\`, smoke, security checks)
- active on-call assignment for deployment window
- rollback operator explicitly assigned

## Review Cadence
- Weekly: check alert noise and unresolved incidents.
- Monthly: run one rollback drill and attach incident note.
DOC

echo "ownership_doc_updated=${DOC_PATH}"
