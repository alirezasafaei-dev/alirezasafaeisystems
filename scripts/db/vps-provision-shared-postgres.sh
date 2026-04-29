#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_BOOTSTRAP="/tmp/asdev-pg-bootstrap.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_BOOTSTRAP' && chmod +x '$REMOTE_BOOTSTRAP' && sudo bash '$REMOTE_BOOTSTRAP' && sudo rm -f '$REMOTE_BOOTSTRAP'"
#!/usr/bin/env bash
set -euo pipefail

SECRET_DIR="/etc/asdev-postgres"
SECRET_FILE="$SECRET_DIR/credentials.env"
mkdir -p "$SECRET_DIR"
chmod 700 "$SECRET_DIR"

ensure_role() {
  local role="$1"
  local pass_var="$2"

  if sudo -u postgres psql -Atqc "SELECT 1 FROM pg_roles WHERE rolname='${role}'" | grep -q 1; then
    echo "role.exists ${role}"
    return 0
  fi

  local password
  password="$(openssl rand -base64 30 | tr -d '\n' | sed 's#[/=+]#A#g')"
  sudo -u postgres psql -v ON_ERROR_STOP=1 -qc "CREATE ROLE \"${role}\" LOGIN PASSWORD '${password}' NOSUPERUSER NOCREATEDB NOCREATEROLE;"
  echo "${pass_var}=${password}" >> "$SECRET_FILE"
  echo "role.created ${role}"
}

ensure_db() {
  local db="$1"
  local owner="$2"

  if sudo -u postgres psql -Atqc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1; then
    echo "db.exists ${db}"
  else
    sudo -u postgres psql -v ON_ERROR_STOP=1 -qc "CREATE DATABASE \"${db}\" OWNER \"${owner}\" ENCODING 'UTF8';"
    echo "db.created ${db} owner=${owner}"
  fi

  sudo -u postgres psql -d "$db" -v ON_ERROR_STOP=1 -qc "GRANT CONNECT ON DATABASE \"${db}\" TO \"${owner}\";"
  sudo -u postgres psql -d "$db" -v ON_ERROR_STOP=1 -qc "GRANT USAGE, CREATE ON SCHEMA public TO \"${owner}\";"
  sudo -u postgres psql -d "$db" -v ON_ERROR_STOP=1 -qc "ALTER SCHEMA public OWNER TO \"${owner}\";"
}

: > "$SECRET_FILE"
chmod 600 "$SECRET_FILE"

echo "# generated $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$SECRET_FILE"

ensure_existing_role() {
  local role="$1"
  if sudo -u postgres psql -Atqc "SELECT 1 FROM pg_roles WHERE rolname='${role}'" | grep -q 1; then
    echo "role.exists ${role}"
  else
    echo "role.missing ${role}"
  fi
}

# Existing stacks (audit/toolbox) - ensure DB isolation exists.
ensure_existing_role "asdev_audit_user"
ensure_db "asdev_audit_production" "asdev_audit_user"
ensure_db "asdev_audit_staging" "asdev_audit_user"

ensure_existing_role "persian_tools_prod"
ensure_db "persian_tools_prod" "persian_tools_prod"

ensure_existing_role "persian_tools_staging"
ensure_db "persian_tools_staging" "persian_tools_staging"

# Portfolio stack - create dedicated production/staging roles + DBs if missing.
ensure_role "asdev_portfolio_prod" "ASDEV_PORTFOLIO_PROD_PASSWORD"
ensure_db "asdev_portfolio_production" "asdev_portfolio_prod"

ensure_role "asdev_portfolio_staging" "ASDEV_PORTFOLIO_STAGING_PASSWORD"
ensure_db "asdev_portfolio_staging" "asdev_portfolio_staging"

# Emit connection URL skeletons (without printing secrets).
{
  echo "DATABASE_URL_PORTFOLIO_PRODUCTION=postgresql://asdev_portfolio_prod:<password>@127.0.0.1:5432/asdev_portfolio_production?schema=public"
  echo "DATABASE_URL_PORTFOLIO_STAGING=postgresql://asdev_portfolio_staging:<password>@127.0.0.1:5432/asdev_portfolio_staging?schema=public"
  echo "DATABASE_URL_AUDIT_PRODUCTION=postgresql://asdev_audit_user:<password>@127.0.0.1:5432/asdev_audit_production?schema=public"
  echo "DATABASE_URL_AUDIT_STAGING=postgresql://asdev_audit_user:<password>@127.0.0.1:5432/asdev_audit_staging?schema=public"
  echo "DATABASE_URL_TOOLBOX_PRODUCTION=postgresql://persian_tools_prod:<password>@127.0.0.1:5432/persian_tools_prod?schema=public"
  echo "DATABASE_URL_TOOLBOX_STAGING=postgresql://persian_tools_staging:<password>@127.0.0.1:5432/persian_tools_staging?schema=public"
} > "$SECRET_DIR/url-hints.env"
chmod 600 "$SECRET_DIR/url-hints.env"

echo "secret_file=$SECRET_FILE"
echo "url_hints=$SECRET_DIR/url-hints.env"
REMOTE

echo "Provisioned/verified shared PostgreSQL isolation on VPS."
