#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
OUT_DIR="${OUT_DIR:-/home/dev/Project_Me_All/Project_Me/alirezasafaeisystems/reports/postgres-audit}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$OUT_DIR/${RUN_ID}-postgres-cluster-audit.md"

mkdir -p "$OUT_DIR"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -u postgres psql -Atqc \"select version();\"" > /tmp/pg_version.txt
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -u postgres psql -Atqc \"SELECT datname, pg_catalog.pg_get_userbyid(datdba) AS owner FROM pg_database WHERE datistemplate = false ORDER BY datname;\"" > /tmp/pg_dbs.txt
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -u postgres psql -Atqc \"SELECT rolname, rolsuper, rolcreatedb, rolcanlogin FROM pg_roles ORDER BY rolname;\"" > /tmp/pg_roles.txt
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -u postgres psql -Atqc \"SELECT datname, numbackends FROM pg_stat_database WHERE datname NOT IN ('template0','template1') ORDER BY datname;\"" > /tmp/pg_backends.txt

{
  echo "# PostgreSQL Cluster Audit"
  echo
  echo "- run_id: $RUN_ID"
  echo "- host: $SSH_HOST"
  echo "- generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "## Version"
  sed -n '1,2p' /tmp/pg_version.txt
  echo
  echo "## Databases"
  echo "| database | owner |"
  echo "|---|---|"
  awk -F'|' '{printf "| %s | %s |\n", $1, $2}' /tmp/pg_dbs.txt
  echo
  echo "## Roles"
  echo "| role | superuser | createdb | canlogin |"
  echo "|---|---|---|---|"
  awk -F'|' '{printf "| %s | %s | %s | %s |\n", $1, $2, $3, $4}' /tmp/pg_roles.txt
  echo
  echo "## Active Backends"
  echo "| database | active_connections |"
  echo "|---|---:|"
  awk -F'|' '{printf "| %s | %s |\n", $1, $2}' /tmp/pg_backends.txt
} > "$OUT_FILE"

echo "POSTGRES_AUDIT_REPORT=$OUT_FILE"
