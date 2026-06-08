#!/bin/bash
set -euo pipefail

# Resubmit the four rollback cases from their current stop point.
# Usage:
#   bash resubmit_crujra_rollbacks.sh [YYYY-MM-DD] [RESUBMIT_COUNT]
# Example:
#   bash resubmit_crujra_rollbacks.sh 2026-06-05 7

USER="rosief"
noresmrepo="ctsm5.4.036_noresm_v0_control"
noresmversion="ctsm5.4.036_noresm_v0"
resolution="ne16pg3_tn14"

rundate="${1:-$(date +"%Y-%m-%d")}"
resubmit_n="${2:-7}"

workpath="/cluster/projects/nn9560k/$USER/"
scriptsdir="${workpath}${noresmrepo}/cime/scripts"

tags=(CSTARV GRAZ MORT RAD)

echo "Resubmitting rollback cases for date ${rundate} with RESUBMIT=${resubmit_n}"

for tag in "${tags[@]}"; do
  case_name="amazon_ppe.${resolution}.${noresmversion}.CRUJRA_2000_${tag}.${rundate}"
  case_dir="${scriptsdir}/${case_name}"

  if [[ ! -d "$case_dir" ]]; then
    echo "Missing case directory: $case_dir"
    exit 1
  fi

  echo "===== ${case_name} ====="
  cd "$case_dir"

  # Continue from latest available restart files.
  ./xmlchange CONTINUE_RUN=TRUE
  ./xmlchange STOP_OPTION=nyears
  ./xmlchange STOP_N=3
  ./xmlchange RESUBMIT="$resubmit_n"

  ./case.setup
  ./preview_namelists
  ./preview_run

  if ./case.submit; then
    echo "Submitted ${case_name}"
  else
    echo "Submission failed for ${case_name}"
    exit 1
  fi
done
