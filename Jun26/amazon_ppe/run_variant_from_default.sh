#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <CSTARV|GRAZ|MORT|RAD>" >&2
  exit 1
fi

TAG="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SCRIPT="$SCRIPT_DIR/FATES_CRUJRA_ne16_beta16_default.sh"
PARAM_FILE="$SCRIPT_DIR/fates_param_rollback_${TAG}.json"

if [[ ! -f "$DEFAULT_SCRIPT" ]]; then
  echo "Missing default script: $DEFAULT_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$PARAM_FILE" ]]; then
  echo "Missing parameter file: $PARAM_FILE" >&2
  exit 1
fi

TMP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/FATES_${TAG}_XXXXXX.sh")"
trap 'rm -f "$TMP_SCRIPT"' EXIT

awk -v tag="$TAG" -v param_file="$PARAM_FILE" '
BEGIN { inserted = 0 }
{
  if ($0 ~ /^[[:space:]]*name='\''[^'\'']*'\''/) {
    print "name='\''" tag "'\'' #name of this setup, used for naming the case and directories. "
    next
  }

  if ($0 ~ /^[[:space:]]*fates_paramfile[[:space:]]*=/) {
    next
  }

  print

  if ($0 ~ /use_fates_lupft=.true./ && inserted == 0) {
    print "fates_paramfile='\''" param_file "'\''"
    inserted = 1
  }
}
END {
  if (inserted == 0) {
    print "Could not find use_fates_lupft=.true. in default script" > "/dev/stderr"
    exit 2
  }
}
' "$DEFAULT_SCRIPT" > "$TMP_SCRIPT"

chmod +x "$TMP_SCRIPT"
bash "$TMP_SCRIPT"
