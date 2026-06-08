#!/bin/bash
set -euo pipefail

cd /cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe

# Step 1: build modified CLM parameter files (SUC/WAT/BSW)
bash make_clm_param_variants.sh

# Step 2: clone/setup/submit three sensitivity cases (defaults to yesterday)
bash FATES_CRUJRA_ne16_beta16_clone_clmparam_tests.sh "${1:-$(date -d 'yesterday' +"%Y-%m-%d")}" 
