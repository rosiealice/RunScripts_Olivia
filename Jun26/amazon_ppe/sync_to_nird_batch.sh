#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash sync_to_nird_batch.sh [list_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_DIR="${SYNC_DIR:-$SCRIPT_DIR/sync_to_nird}"
mkdir -p "$SYNC_DIR"

LIST_FILE="${1:-$SYNC_DIR/nird-sync-list.txt}"
LOG_FILE="$SYNC_DIR/nird-sync-$(date +%Y%m%d-%H%M%S).log"
REMOTE="rosief@nird.sigma2.no:/datalake/NS9560K/rosief//"

if [[ ! -f "$LIST_FILE" ]]; then
  echo "List file not found: $LIST_FILE"
  exit 1
fi

# Resumable, recursive, single-connection transfer.
# Exclude heavy restart trees to reduce transfer time.
RSYNC_BASE=(
  rsync -aP --append-verify --partial --info=progress2
  --exclude='rest/'
  --exclude='**/rest/**'
)
if [[ -n "${RSYNC_CHOWN:-}" ]]; then
  RSYNC_BASE+=(--chown="$RSYNC_CHOWN")
fi

count=0
missing=0
queued=0
sources=()

while IFS= read -r raw; do
  [[ -z "${raw// /}" || "$raw" =~ ^[[:space:]]*# ]] && continue
  dir="$raw"
  count=$((count + 1))

  if [[ ! -d "$dir" ]]; then
    echo "[$count] missing, skipping: $dir" | tee -a "$LOG_FILE"
    missing=$((missing + 1))
    continue
  fi

  queued=$((queued + 1))
  echo "[$count] queued: $dir"
  sources+=("$dir")
done < "$LIST_FILE"

if [[ "$queued" -eq 0 ]]; then
  echo "No valid directories to sync. checked=$count missing=$missing"
  exit 1
fi

echo
echo "Starting single-connection rsync batch"
echo "List: $LIST_FILE"
echo "Queued directories: $queued"
echo "Skipped missing: $missing"
echo "Destination: $REMOTE"
echo "Log: $LOG_FILE"
echo "Excluded: directories named 'rest'"
echo

echo "Running rsync (one authentication session)..."
if "${RSYNC_BASE[@]}" "${sources[@]}" "$REMOTE" | tee -a "$LOG_FILE"; then
  echo
  echo "Batch sync completed successfully."
else
  rc=$?
  echo
  echo "Batch sync ended with rc=$rc. See log: $LOG_FILE"
  echo "Re-run the same command to resume interrupted files."
  exit $rc
fi
