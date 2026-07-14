#!/usr/bin/env bash
set -Euo pipefail

CONTRACT_FILE="${1:?usage: validate-task-artifact.sh <contract.json> [artifact_path]}"
ARTIFACT_PATH="${2:-}"
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SDIR}/task-contract.schema.json"

test -f "$CONTRACT_FILE" || { echo "ARTIFACT_INVALID contract-not-found"; exit 1; }
test -f "$SCHEMA_FILE" || { echo "ARTIFACT_INVALID schema-not-found"; exit 1; }

RAW="$(cat "$CONTRACT_FILE")"

python3 -c "import json; json.load(open('$CONTRACT_FILE'))" 2>/dev/null || { echo "ARTIFACT_INVALID not-valid-json"; exit 1; }

SCHEMA_RESULT=$(python3 -c "
import json, sys, re
c = json.load(open('$CONTRACT_FILE'))
s = json.load(open('$SCHEMA_FILE'))
errors = []
for f in s.get('required', []):
    if f not in c: errors.append('missing:' + f)
for k in list(c.keys()):
    if k not in s.get('properties', {}):
        if s.get('additionalProperties') is False and not k.startswith('_'):
            errors.append('unknown:' + k)
    else:
        p = s['properties'][k]
        if 'type' in p:
            val = c[k]
            if p['type'] == 'string' and not isinstance(val, str): errors.append('type:' + k)
            elif p['type'] == 'integer' and not isinstance(val, int): errors.append('type:' + k)
        if 'pattern' in p:
            if not re.match(p['pattern'], str(c[k])): errors.append('format:' + k)
        if 'enum' in p:
            if c[k] not in p['enum']: errors.append('enum:' + k + '=' + str(c[k]))
        if 'minimum' in p:
            if not isinstance(c[k], int) or c[k] < p['minimum']: errors.append('min:' + k)
        if 'maximum' in p:
            if not isinstance(c[k], int) or c[k] > p['maximum']: errors.append('max:' + k)
if errors:
    print(';'.join(errors)); sys.exit(1)
print('SCHEMA_OK')
" 2>&1) || { echo "ARTIFACT_INVALID $SCHEMA_RESULT"; exit 1; }

MODE=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('mode',''))")
FM=0; for m in read-only code docs-only automation-script; do [ "$m" = "$MODE" ] && FM=1; done
[ "$FM" -eq 1 ] || { echo "ARTIFACT_INVALID disallowed-mode:$MODE"; exit 1; }

REPO=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('repository',''))")
FR=0; for r in alirezasafaei-dev/alirezasafaeisystems alirezasafaei-dev/auditsystems; do [ "$r" = "$REPO" ] && FR=1; done
[ "$FR" -eq 1 ] || { echo "ARTIFACT_INVALID disallowed-repo:$REPO"; exit 1; }

EXPECTED_ARTIFACT=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expected_artifact',''))")
ARTIFACT_VALIDATOR=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('artifact_validator',''))")
VALIDATION_COMMAND=$(echo "$RAW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('validation_command',''))")

if [ -n "$ARTIFACT_PATH" ]; then
  [ -f "$ARTIFACT_PATH" ] || { echo "ARTIFACT_INVALID not-found:$ARTIFACT_PATH"; exit 1; }
  [ -s "$ARTIFACT_PATH" ] || { echo "ARTIFACT_INVALID empty:$ARTIFACT_PATH"; exit 1; }
  ARTIFACT_SHA=$(sha256sum "$ARTIFACT_PATH" | cut -d" " -f1)
else
  ARTIFACT_SHA=""
fi

VALIDATOR_EXIT=0
if [ -n "$ARTIFACT_VALIDATOR" ] && [ -z "${ASDEV_VALIDATOR_BUSY:-}" ]; then
  ROOT="${ASDEV_ROOT:-$(cd "$SDIR/../../.." && pwd)}"
  VALIDATOR_SCRIPT="$ROOT/$ARTIFACT_VALIDATOR"
  if [ -x "$VALIDATOR_SCRIPT" ]; then
    export ASDEV_VALIDATOR_BUSY=1
    bash "$VALIDATOR_SCRIPT" "$CONTRACT_FILE" "$ARTIFACT_PATH" || VALIDATOR_EXIT=$?
    [ "$VALIDATOR_EXIT" -eq 0 ] || { echo "ARTIFACT_INVALID validator-exit=$VALIDATOR_EXIT"; exit 1; }
  fi
fi

VALIDATION_EXIT=0
if [ -n "$VALIDATION_COMMAND" ] && [ -n "$ARTIFACT_PATH" ]; then
  eval "$VALIDATION_COMMAND" >/dev/null 2>&1 || VALIDATION_EXIT=$?
  [ "$VALIDATION_EXIT" -eq 0 ] || { echo "ARTIFACT_INVALID validation-exit=$VALIDATION_EXIT"; exit 1; }
fi

echo "ARTIFACT_VALID sha256=$ARTIFACT_SHA"
