#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" 'bash -s' <<'REMOTE'
set -euo pipefail

domains=(
  "https://persiantoolbox.ir"
  "https://alirezasafaeisystems.ir"
  "https://audit.alirezasafaeisystems.ir"
)

ts="$(date -u +%Y%m%dT%H%M%SZ)"
report_dir="${HOME}/asdev-monitoring"
report="${report_dir}/seo-smoke-${ts}.md"
mkdir -p "${report_dir}"

{
  echo "# SEO Smoke Report"
  echo
  echo "- generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  failed=0
  for base in "${domains[@]}"; do
    host="${base#https://}"
    robots_tmp="$(mktemp)"
    sitemap_tmp="$(mktemp)"
    home_tmp="$(mktemp)"

    if ! getent hosts "${host}" >/dev/null 2>&1; then
      echo "## ${base}"
      echo "- dns_resolve: fail"
      echo "- checks: fail:dns"
      echo
      failed=1
      rm -f "${robots_tmp}" "${sitemap_tmp}" "${home_tmp}"
      continue
    fi

    echo "## ${base}"
    robots_code="$(curl -sS -o "${robots_tmp}" -w "%{http_code}" "${base}/robots.txt" || echo "000")"
    sitemap_code="$(curl -sS -o "${sitemap_tmp}" -w "%{http_code}" "${base}/sitemap.xml" || echo "000")"
    home_code="$(curl -sS -o "${home_tmp}" -w "%{http_code}" "${base}/" || echo "000")"
    canon_count="$(grep -Eic '<link[^>]+rel=["'"'"']canonical["'"'"']' "${home_tmp}" || true)"
    hreflang_count="$(grep -Eic 'hreflang=' "${home_tmp}" || true)"
    og_title_count="$(grep -Eic 'property=["'"'"']og:title["'"'"']' "${home_tmp}" || true)"
    tw_card_count="$(grep -Eic 'name=["'"'"']twitter:card["'"'"']' "${home_tmp}" || true)"

    echo "- dns_resolve: ok"
    echo "- robots.txt: ${robots_code}"
    echo "- sitemap.xml: ${sitemap_code}"
    echo "- homepage: ${home_code}"
    echo "- canonical_tag_count: ${canon_count}"
    echo "- hreflang_tag_count: ${hreflang_count}"
    echo "- og_title_tag_count: ${og_title_count}"
    echo "- twitter_card_tag_count: ${tw_card_count}"
    checks="ok"
    if [[ "${robots_code}" != "200" || "${sitemap_code}" != "200" || "${home_code}" != "200" ]]; then
      checks="fail:http"
      failed=1
    elif (( canon_count < 1 || og_title_count < 1 || tw_card_count < 1 )); then
      checks="fail:meta"
      failed=1
    elif (( hreflang_count < 1 )); then
      if [[ "${host}" == "persiantoolbox.ir" ]]; then
        checks="ok:single-locale"
      else
        checks="warn:hreflang"
      fi
    fi
    echo "- checks: ${checks}"
    echo
    rm -f "${robots_tmp}" "${sitemap_tmp}" "${home_tmp}"
  done
  echo "- overall: $([[ ${failed} -eq 0 ]] && echo pass || echo fail)"
} > "$report"

ln -sfn "$report" "${report_dir}/seo-smoke-latest.md"
echo "$report"
cat "$report"
if grep -q -- "- overall: fail" "$report"; then
  exit 1
fi
REMOTE
