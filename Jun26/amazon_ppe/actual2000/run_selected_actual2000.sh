#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

bash FATES_CRUJRA_ne16_beta16_default.sh
bash FATES_CRUJRA_ne16_beta16_GRAZ.sh
bash FATES_CRUJRA_ne16_beta16_MORT.sh
bash FATES_CRUJRA_ne16_beta16_VCM.sh
bash FATES_CRUJRA_ne16_beta16_GRR.sh
