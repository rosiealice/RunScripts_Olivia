#!/bin/bash
set -euo pipefail

module load NRIS/CPU
module load Python/3.12.3-GCCcore-13.3.0

# Clone three CLM-parameter sensitivity cases (SUC, WAT, BSW) from built default.
# Usage:
#   bash FATES_CRUJRA_ne16_beta16_clone_clmparam_tests.sh [YYYY-MM-DD]

dosetup=1
dosubmit=1
forcenewcase=0

USER="rosief"
noresmrepo="ctsm5.4.036_noresm_v0_control"
noresmversion="ctsm5.4.036_noresm_v0"
resolution="ne16pg3_tn14"

# Defaults to yesterday's date per request.
rundate="${1:-$(date -d 'yesterday' +"%Y-%m-%d")}" 

workpath="/cluster/projects/nn9560k/$USER/"
scriptsdir="${workpath}${noresmrepo}/cime/scripts"

base_case="${scriptsdir}/amazon_ppe.${resolution}.${noresmversion}.CRUJRA_2000_default.${rundate}"

if [[ ! -d "$base_case" ]]; then
  echo "Base default case not found: $base_case"
  exit 1
fi
if [[ ! -x "$scriptsdir/create_clone" ]]; then
  echo "create_clone not found: $scriptsdir/create_clone"
  exit 1
fi

# Ensure base exe exists for --keepexe.
base_exeroot="$(cd "$base_case" && ./xmlquery EXEROOT --value)"
if [[ ! -x "$base_exeroot/cesm.exe" ]]; then
  echo "Missing base executable: $base_exeroot/cesm.exe"
  exit 1
fi

declare -A PARAMFILES
PARAMFILES[SUC]="/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams/ctsm60_params.noresm.c260406_SUC.nc"
PARAMFILES[WAT]="/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams/ctsm60_params.noresm.c260406_WAT.nc"
PARAMFILES[BSW]="/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams/ctsm60_params.noresm.c260406_BSW.nc"

tags=(SUC WAT BSW)

for tag in "${tags[@]}"; do
  clone_name="amazon_ppe.${resolution}.${noresmversion}.CRUJRA_2000_${tag}.${rundate}"
  clone_case="${scriptsdir}/${clone_name}"
  param_file="${PARAMFILES[$tag]}"

  if [[ ! -f "$param_file" ]]; then
    echo "Missing CLM param file for ${tag}: $param_file"
    exit 1
  fi

  if [[ $dosetup -eq 1 ]]; then
    if [[ $forcenewcase -eq 1 && -d "$clone_case" ]]; then
      rm -rf "$clone_case"
      rm -rf "/cluster/work/projects/nn9560k/$USER/noresm/$clone_name"
      rm -rf "/cluster/work/projects/nn9560k/$USER/archive/$clone_name"
    fi

    if [[ ! -d "$clone_case" ]]; then
      echo "Creating clone: $clone_case"
      "$scriptsdir/create_clone" --case "$clone_case" --clone "$base_case" --keepexe
    else
      echo "Clone exists: $clone_case"
    fi

    cd "$clone_case"

    if [[ -f user_nl_clm ]]; then
      grep -v "^[[:space:]]*paramfile[[:space:]]*=" user_nl_clm > user_nl_clm.tmp || true
      mv user_nl_clm.tmp user_nl_clm
    fi

    echo "paramfile='$param_file'" >> user_nl_clm

    ./xmlchange CONTINUE_RUN=FALSE
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange STOP_N=3
    ./xmlchange RESUBMIT=7

    ./case.setup
    ./preview_namelists
    ./preview_run

    echo "Configured $clone_name with paramfile=$param_file"
  fi

  if [[ $dosubmit -eq 1 ]]; then
    cd "$clone_case"
    ./case.submit
    echo "Submitted $clone_name"
  fi
done
