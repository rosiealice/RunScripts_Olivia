#!/bin/bash

module load NRIS/CPU
module load Python/3.12.3-GCCcore-13.3.0

# Run DEFAULT first (create/build/optional submit), then clone rollback cases
# with --keepexe and set per-case fates_paramfile.
# Usage:
#   bash FATES_CRUJRA_ne16_beta16_clone_rollbacks.sh [YYYY-MM-DD]

dosetup=1
# 1: run setup/build for default and configure clone cases
# 0: skip setup/build and only submit existing cases

dosubmit=1
# 1: submit default and clone cases
# 0: do not submit

forcenewcase=0
force_base_rebuild=0  # if 1, rerun the default case build even when BUILD_COMPLETE is TRUE

stop_option="nyears"
stop_n=3
resubmit_n=7

echo "clone setup, submit, forcenewcase, force_base_rebuild:", $dosetup, $dosubmit, $forcenewcase, $force_base_rebuild

USER="rosief"
noresmrepo="ctsm5.4.036_noresm_v0_control"
noresmversion="ctsm5.4.036_noresm_v0"
resolution="ne16pg3_tn14"

rundate="${1:-$(date +"%Y-%m-%d")}" 
workpath="/cluster/projects/nn9560k/$USER/"
scriptsdir="$workpath$noresmrepo/cime/scripts/"
scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

default_driver="$scriptdir/FATES_CRUJRA_ne16_beta16_default.sh"

base_name="amazon_ppe.$resolution.$noresmversion.CRUJRA_2000_default.$rundate"
base_case="$scriptsdir$base_name"

if [[ ! -x "$default_driver" ]]; then
    echo "Default driver script not found: $default_driver"
    exit 1
fi

if [[ ! -x "$scriptsdir/create_clone" ]]; then
    echo "create_clone not found in cime scripts: $scriptsdir/create_clone"
    exit 1
fi

# Include default in loop as requested.
tags=(default CSTARV GRAZ MORT RAD)

for tag in "${tags[@]}"; do
    if [[ "$tag" == "default" ]]; then
        if [[ -d "$base_case" && $force_base_rebuild -eq 0 ]]; then
            if [[ ! -x "$base_case/xmlquery" ]]; then
                echo "xmlquery missing in base case: $base_case/xmlquery"
                exit 1
            fi
            base_build_complete="$(cd "$base_case" && ./xmlquery BUILD_COMPLETE --value)"
            if [[ "$base_build_complete" == "TRUE" ]]; then
                echo "Default base case already built; skipping rebuild: $base_case"
            else
                echo "Base case exists but BUILD_COMPLETE is not TRUE; rebuilding default case"
                NAME_OVERRIDE="default" \
                RUNDATE_OVERRIDE="$rundate" \
                DOSETUP1_OVERRIDE=1 \
                DOSETUP2_OVERRIDE=1 \
                DOSETUP3_OVERRIDE=1 \
                DOSUBMIT_OVERRIDE=0 \
                FORCENEWCASE_OVERRIDE=1 \
                bash "$default_driver"
            fi
        else
            if [[ $force_base_rebuild -eq 1 && -d "$base_case" ]]; then
                echo "Force rebuild requested; removing existing base case: $base_case"
                rm -rf "$base_case"
                rm -rf "/cluster/work/projects/nn9560k/$USER/noresm/$base_name"
                rm -rf "/cluster/work/projects/nn9560k/$USER/archive/$base_name"
            fi
            echo "Running default case workflow for date $rundate"
            NAME_OVERRIDE="default" \
            RUNDATE_OVERRIDE="$rundate" \
            DOSETUP1_OVERRIDE=1 \
            DOSETUP2_OVERRIDE=1 \
            DOSETUP3_OVERRIDE=1 \
            DOSUBMIT_OVERRIDE=0 \
            FORCENEWCASE_OVERRIDE=1 \
            bash "$default_driver"
        fi

        if [[ ! -d "$base_case" ]]; then
            echo "Default case was not created: $base_case"
            exit 1
        fi

        cd "$base_case"
        ./xmlchange STOP_OPTION="$stop_option"
        ./xmlchange STOP_N="$stop_n"
        ./xmlchange RESUBMIT="$resubmit_n"
        ./case.setup
        ./preview_namelists
        ./preview_run

        if [[ $dosubmit -eq 1 ]]; then
            if ./case.submit; then
                echo "Submitted default"
            else
                echo "Submission failed for default"
                exit 1
            fi
        fi

        # For --keepexe clones we need a built base executable when setup is on.
        if [[ $dosetup -eq 1 ]]; then
            if [[ ! -x "$base_case/xmlquery" ]]; then
                echo "xmlquery missing in base case: $base_case/xmlquery"
                exit 1
            fi
            base_exeroot="$(cd "$base_case" && ./xmlquery EXEROOT --value)"
            base_exe="$base_exeroot/cesm.exe"
            if [[ ! -x "$base_exe" ]]; then
                echo "Base case appears unbuilt, missing: $base_exe"
                exit 1
            fi
            echo "Base executable ready: $base_exe"
        fi

        continue
    fi

    clone_name="amazon_ppe.$resolution.$noresmversion.CRUJRA_2000_${tag}.$rundate"
    clone_case="$scriptsdir$clone_name"
    param_file="$scriptdir/fates_param_rollback_${tag}.json"

    if [[ ! -f "$param_file" ]]; then
        echo "Missing parameter file: $param_file"
        exit 1
    fi

    if [[ $dosetup -eq 1 ]]; then
        if [[ ! -d "$base_case" ]]; then
            echo "Base default case not found for cloning: $base_case"
            exit 1
        fi

        if [[ $forcenewcase -eq 1 && -d "$clone_case" ]]; then
            echo "Removing existing clone case and run/archive dirs for $clone_name"
            rm -rf "$clone_case"
            rm -rf "/cluster/work/projects/nn9560k/$USER/noresm/$clone_name"
            rm -rf "/cluster/work/projects/nn9560k/$USER/archive/$clone_name"
        fi

        if [[ -d "$clone_case" ]]; then
            echo "Clone case already exists: $clone_case"
        else
            echo "Creating clone: $clone_case"
            "$scriptsdir/create_clone" --case "$clone_case" --clone "$base_case" --keepexe
        fi

        cd "$clone_case"

        # Ensure only one fates_paramfile line remains.
        if [[ -f user_nl_clm ]]; then
            grep -v "^[[:space:]]*fates_paramfile[[:space:]]*=" user_nl_clm > user_nl_clm.tmp || true
            mv user_nl_clm.tmp user_nl_clm
        fi

        echo "fates_paramfile='$param_file'" >> user_nl_clm

        # Ensure run-control settings are carried into cloned cases.
        ./xmlchange STOP_OPTION="$stop_option"
        ./xmlchange STOP_N="$stop_n"
        ./xmlchange RESUBMIT="$resubmit_n"

        # Regenerate case metadata, namelists, and batch/run scripts after user_nl_clm changes.
        ./case.setup
        ./preview_namelists
        ./preview_run

        echo "Configured $clone_name with $param_file"
    fi

    if [[ $dosubmit -eq 1 ]]; then
        cd "$clone_case"
        if ./case.submit; then
            echo "Submitted $clone_name"
        else
            echo "Submission failed for $clone_name"
            exit 1
        fi
    fi
done
