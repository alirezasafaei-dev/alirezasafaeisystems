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
