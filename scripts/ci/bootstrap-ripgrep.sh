#!/usr/bin/env bash
set -euo pipefail

RIPGREP_VERSION="14.1.1"
RIPGREP_TARGET="x86_64-unknown-linux-musl"
RIPGREP_ARCHIVE="ripgrep-${RIPGREP_VERSION}-${RIPGREP_TARGET}.tar.gz"
RIPGREP_CHECKSUM="ripgrep-${RIPGREP_VERSION}-${RIPGREP_TARGET}.tar.gz.sha256"
RIPGREP_BASE_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}"

for required in curl tar sha256sum install; do
  if ! command -v "$required" >/dev/null 2>&1; then
    echo "::error::Cannot provision ripgrep: required tool '$required' is unavailable." >&2
    exit 2
  fi
done

if [ -z "${GITHUB_PATH:-}" ]; then
  echo "::error::Cannot provision ripgrep safely: GITHUB_PATH is unavailable." >&2
  exit 2
fi

RUN_TEMP="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
WORK_DIR="$(mktemp -d "${RUN_TEMP%/}/asdev-ripgrep.XXXXXX")"
INSTALL_DIR="${RUN_TEMP%/}/asdev-tools/ripgrep-${RIPGREP_VERSION}/bin"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$INSTALL_DIR"

curl --fail --location --silent --show-error \
  --retry 3 --retry-delay 2 \
  "${RIPGREP_BASE_URL}/${RIPGREP_ARCHIVE}" \
  --output "${WORK_DIR}/${RIPGREP_ARCHIVE}"

curl --fail --location --silent --show-error \
  --retry 3 --retry-delay 2 \
  "${RIPGREP_BASE_URL}/${RIPGREP_CHECKSUM}" \
  --output "${WORK_DIR}/${RIPGREP_CHECKSUM}"

(
  cd "$WORK_DIR"
  sha256sum -c "$RIPGREP_CHECKSUM"
)

tar -xzf "${WORK_DIR}/${RIPGREP_ARCHIVE}" -C "$WORK_DIR"
install -m 0755 \
  "${WORK_DIR}/ripgrep-${RIPGREP_VERSION}-${RIPGREP_TARGET}/rg" \
  "${INSTALL_DIR}/rg"

"${INSTALL_DIR}/rg" --version | head -n 1
printf '%s\n' "$INSTALL_DIR" >> "$GITHUB_PATH"

echo "Provisioned checksum-verified ripgrep ${RIPGREP_VERSION} in job-local runner temp state."
