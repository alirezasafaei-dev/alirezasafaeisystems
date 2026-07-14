#!/usr/bin/env bash
set -Euo pipefail

CONTRACT_FILE="${1:?usage: validate-task-artifact.sh <contract.json> [artifact_path]}"
SUPPLIED_ARTIFACT="${2:-}"
ACC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$ACC_DIR/task-contract.schema.json"
ROOT="${ASDEV_ROOT:-$(cd "$ACC_DIR/../.." && pwd)}"

[ -f "$CONTRACT_FILE" ] || { echo "ARTIFACT_INVALID contract-not-found"; exit 1; }
[ -f "$SCHEMA_FILE" ] || { echo "ARTIFACT_INVALID schema-not-found"; exit 1; }

set +e
SCHEMA_RESULT="$(python3 - "$CONTRACT_FILE" "$SCHEMA_FILE" <<'PY'
import json
import re
import sys

contract_path, schema_path = sys.argv[1:]
try:
    with open(contract_path, encoding="utf-8") as handle:
        contract = json.load(handle)
    with open(schema_path, encoding="utf-8") as handle:
        schema = json.load(handle)
except (OSError, json.JSONDecodeError) as exc:
    print(f"not-valid-json:{type(exc).__name__}")
    raise SystemExit(1)

if not isinstance(contract, dict):
    print("type:root")
    raise SystemExit(1)

errors = []
properties = schema.get("properties", {})
for name in schema.get("required", []):
    if name not in contract:
        errors.append(f"missing:{name}")

if schema.get("additionalProperties") is False:
    for name in contract:
        if name not in properties:
            errors.append(f"unknown:{name}")

for name, value in contract.items():
    rule = properties.get(name)
    if not rule:
        continue
    expected_type = rule.get("type")
    if expected_type == "string" and not isinstance(value, str):
        errors.append(f"type:{name}")
        continue
    if expected_type == "integer" and (not isinstance(value, int) or isinstance(value, bool)):
        errors.append(f"type:{name}")
        continue
    if "minLength" in rule and len(value) < rule["minLength"]:
        errors.append(f"minLength:{name}")
    if "pattern" in rule and re.fullmatch(rule["pattern"], value) is None:
        errors.append(f"format:{name}")
    if "enum" in rule and value not in rule["enum"]:
        errors.append(f"enum:{name}")
    if "minimum" in rule and value < rule["minimum"]:
        errors.append(f"minimum:{name}")
    if "maximum" in rule and value > rule["maximum"]:
        errors.append(f"maximum:{name}")

if contract.get("repository") not in {
    "alirezasafaei-dev/alirezasafaeisystems",
    "alirezasafaei-dev/auditsystems",
}:
    errors.append("allowlist:repository")

repo_tail = contract.get("repo_path", "").removeprefix("repos/")
if repo_tail != contract.get("repository"):
    errors.append("binding:repo_path")

if errors:
    print(";".join(errors))
    raise SystemExit(1)
print("SCHEMA_OK")
PY
)"
SCHEMA_EXIT=$?
set -e
if [ "$SCHEMA_EXIT" -ne 0 ]; then
  echo "ARTIFACT_INVALID $SCHEMA_RESULT"
  exit 1
fi

if [ -z "$SUPPLIED_ARTIFACT" ]; then
  echo "CONTRACT_VALID"
  exit 0
fi

EXPECTED_ARTIFACT="$(python3 - "$CONTRACT_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["expected_artifact"])
PY
)"
VALIDATION_ID="$(python3 - "$CONTRACT_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["validation_command"])
PY
)"

EXPECTED_PATH="$(realpath -m "$ROOT/$EXPECTED_ARTIFACT")"
ACTUAL_PATH="$(realpath -m "$SUPPLIED_ARTIFACT")"
case "$EXPECTED_PATH" in
  "$ROOT"/*) ;;
  *) echo "ARTIFACT_INVALID expected-path-escape"; exit 1 ;;
esac
[ "$ACTUAL_PATH" = "$EXPECTED_PATH" ] || {
  echo "ARTIFACT_INVALID artifact-contract-mismatch"
  exit 1
}
[ -f "$ACTUAL_PATH" ] || { echo "ARTIFACT_INVALID not-found:$EXPECTED_ARTIFACT"; exit 1; }
[ -s "$ACTUAL_PATH" ] || { echo "ARTIFACT_INVALID empty:$EXPECTED_ARTIFACT"; exit 1; }
if [ -n "${ASDEV_SECRET_CANARY:-}" ] && grep -Fq -- "$ASDEV_SECRET_CANARY" "$ACTUAL_PATH"; then
  echo "ARTIFACT_INVALID secret-canary-present"
  exit 1
fi
if grep -Eq 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}' "$ACTUAL_PATH"; then
  echo "ARTIFACT_INVALID secret-pattern-present"
  exit 1
fi

case "$VALIDATION_ID" in
  artifact-nonempty)
    ;;
  markdown-report)
    grep -Eq '^#([#]*)[[:space:]]+[^[:space:]]' "$ACTUAL_PATH" || {
      echo "ARTIFACT_INVALID markdown-heading-required"
      exit 1
    }
    ;;
  json-object)
    python3 - "$ACTUAL_PATH" <<'PY' || {
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
raise SystemExit(0 if isinstance(value, dict) else 1)
PY
      echo "ARTIFACT_INVALID json-object-required"
      exit 1
    }
    ;;
  *)
    echo "ARTIFACT_INVALID validation-id-not-allowlisted:$VALIDATION_ID"
    exit 1
    ;;
esac

ARTIFACT_SHA="$(sha256sum "$ACTUAL_PATH" | awk '{print $1}')"
echo "ARTIFACT_VALID sha256=$ARTIFACT_SHA"
