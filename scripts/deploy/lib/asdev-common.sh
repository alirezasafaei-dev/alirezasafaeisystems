#!/usr/bin/env bash
# Shared helpers for ASDEV deploy engine scripts.
# Safe to source; does not mutate system state.

# shellcheck disable=SC2034
ASDEV_COMMON_LOADED=1

asdev_script_dir() {
  cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

asdev_project_root_from() {
  local script_dir="$1"
  dirname "$(dirname "$script_dir")"
}

# Resolve on-disk source directory for a registry site.
# Order:
#   1. ASDEV_SITE_SRC_OVERRIDE (absolute path for one-shot runs)
#   2. ASDEV_SITES_ROOT/<site_id> if directory exists
#   3. PROJECT_ROOT/<repo_path> from registry
#   4. Special-case: alirezasafaeisystems falls back to PROJECT_ROOT when monorepo root is the app
asdev_resolve_site_src() {
  local project_root="$1"
  local site_id="$2"
  local repo_path="$3"
  local candidate=""

  if [[ -n "${ASDEV_SITE_SRC_OVERRIDE:-}" ]]; then
    printf '%s\n' "$ASDEV_SITE_SRC_OVERRIDE"
    return 0
  fi

  if [[ -n "${ASDEV_SITES_ROOT:-}" ]]; then
    candidate="${ASDEV_SITES_ROOT%/}/${site_id}"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  if [[ -n "$repo_path" && "$repo_path" != "-" ]]; then
    candidate="${project_root%/}/${repo_path}"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  if [[ "$site_id" == "alirezasafaeisystems" && -f "${project_root}/package.json" ]]; then
    printf '%s\n' "$project_root"
    return 0
  fi

  # Return expected path even if missing (callers warn).
  if [[ -n "$repo_path" && "$repo_path" != "-" ]]; then
    printf '%s\n' "${project_root%/}/${repo_path}"
  else
    printf '%s\n' "${project_root%/}/sites/live/${site_id}"
  fi
}

asdev_site_src_status() {
  local path="$1"
  if [[ -d "$path" && -f "${path}/package.json" ]]; then
    echo "ready"
  elif [[ -d "$path" ]]; then
    echo "partial"
  else
    echo "missing"
  fi
}

# Registry column numbers (21-col schema)
# 12 = prod_port (legacy name healthcheck_port accepted in validators)
# 21 = staging_port
ASDEV_COL_PROD_PORT=12
ASDEV_COL_STAGING_PORT=21

# Resolve runtime/health port for an environment from registry fields.
# Args: environment prod_port staging_port
asdev_resolve_env_port() {
  local environment="$1"
  local prod_port="$2"
  local staging_port="${3:-}"
  if [[ "$environment" == "staging" ]]; then
    if [[ -n "$staging_port" && "$staging_port" != "-" ]]; then
      printf '%s\n' "$staging_port"
    else
      printf '%s\n' "$prod_port"
    fi
  else
    printf '%s\n' "$prod_port"
  fi
}

# Return 0 if TCP port is listening locally
asdev_port_is_listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    if ss -lnt 2>/dev/null | grep -E ":${port}\\b" | grep -q LISTEN; then
      return 0
    fi
    return 1
  fi
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi
  return 1
}

# True if path looks like a DB migration change
asdev_path_is_migration() {
  local f="$1"
  case "$f" in
    *migration*|*migrations*|prisma/migrations/*|**/migrate/*|db/migrate/*)
      return 0
      ;;
  esac
  return 1
}
