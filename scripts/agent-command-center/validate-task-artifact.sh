#!/usr/bin/env bash
set -Euo pipefail

CONTRACT_FILE="${1:?usage: validate-task-artifact.sh <contract.json> [artifact_path]}"
ARTIFACT_PATH="${2:-}"
SDIR="$(dirname "${BASH_SOURCE[0]}")"

if [ ! -f "$CONTRACT_FILE" ]; then
  echo "ARTIFACT_INVALID contract-file-not-found"
  exit 1
fi
RAW="$(cat "$CONTRACT_FILE")"

# Extract fields safely (obfuscated python to avoid shell parsing)
MODE=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('mode',''))" 2>/dev/null || echo "")
REPO=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('repository',''))" 2>/dev/null || echo "")
SHA=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expected_sha',''))" 2>/dev/null || echo "")

# Check mode allowlist
ALLOWED_MODES="read-only code docs-only automation-script"
if [ -n "$MODE" ]; then
  FM=0
  for m in $ALLOWED_MODES; do [ "$m" = "$MODE" ] && FM=1; done
  [ "$FM" -eq 0 ] && { echo "ARTIFACT_INVALID disallowed-mode: $MODE"; exit 1; }
fi

# Check repo allowlist
ALLOWED_REPOS="alirezasafaei-dev/alirezasafaeisystems alirezasafaei-dev/auditsystems"
if [ -n "$REPO" ]; then
  FR=0
  for r in $ALLOWED_REPOS; do [ "$r" = "$REPO" ] && FR=1; done
  [ "$FR" -eq 0 ] && { echo "ARTIFACT_INVALID disallowed-repo: $REPO"; exit 1; }
fi

# Validate against schema
SCHEMA_FILE="${SDIR}/task-contract.schema.json"
python3 -c "
import json, sys, re
try:
    c = json.load(open('$CONTRACT_FILE'))
except:
    print('not-valid-json')
    sys.exit(1)
s = json.load(open('$SCHEMA_FILE'))
errors = []
for f in s.get('required', []):
    if f not in c: errors.append('missing:' + f)
for k in list(c.keys()):
    if k not in s.get('properties', {}):
        if s.get('additionalProperties') is False:
            if not k.startswith('_'): errors.append('unknown:' + k)
    else:
        p = s['properties'][k]
        if 'pattern' in p and not re.match(p['pattern'], str(c[k])): errors.append('format:' + k)
        if 'enum' in p and c[k] not in p['enum']: errors.append('enum:' + k)
if errors:
    print(';'.join(errors))
    sys.exit(1)
print('SCHEMA_OK')
" 2>&1 || { echo "CONTRACT_INVALID schema"; exit 1; }

# Check artifact
if [ -n "$ARTIFACT_PATH" ]; then
  [ ! -f "$ARTIFACT_PATH" ] && { echo "ARTIFACT_INVALID not-found"; exit 1; }
  [ ! -s "$ARTIFACT_PATH" ] && { echo "ARTIFACT_INVALID empty"; exit 1; }
  ASHA=$(sha256sum "$ARTIFACT_PATH" | cut -d' ' -f1)
  echo "ARTIFACT_VALID sha256=$ASHA"
else
  echo "ARTIFACT_VALID no-artifact"
fi
