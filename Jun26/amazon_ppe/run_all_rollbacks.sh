#!/bin/bash
set -euo pipefail

cd /cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe

bash FATES_CRUJRA_ne16_beta16_default.sh

bash FATES_CRUJRA_ne16_beta16_CSTARV.sh
bash FATES_CRUJRA_ne16_beta16_GRAZ.sh
bash FATES_CRUJRA_ne16_beta16_MORT.sh
bash FATES_CRUJRA_ne16_beta16_RAD.sh
