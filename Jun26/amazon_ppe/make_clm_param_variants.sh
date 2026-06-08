#!/bin/bash
set -euo pipefail

module load NRIS/CPU
module load Python/3.12.3-GCCcore-13.3.0

BASE="/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams/ctsm60_params.noresm.c260406.nc"
OUTDIR="/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams"

if [[ ! -f "$BASE" ]]; then
  echo "Missing base CLM parameter file: $BASE"
  exit 1
fi

cp -f "$BASE" "$OUTDIR/ctsm60_params.noresm.c260406_SUC.nc"
cp -f "$BASE" "$OUTDIR/ctsm60_params.noresm.c260406_WAT.nc"
cp -f "$BASE" "$OUTDIR/ctsm60_params.noresm.c260406_BSW.nc"

ncap2 -O -s 'sucsat_sf=1.2' "$OUTDIR/ctsm60_params.noresm.c260406_SUC.nc" "$OUTDIR/ctsm60_params.noresm.c260406_SUC.nc"
ncap2 -O -s 'watsat_sf=1.2' "$OUTDIR/ctsm60_params.noresm.c260406_WAT.nc" "$OUTDIR/ctsm60_params.noresm.c260406_WAT.nc"
ncap2 -O -s 'bsw_sf=3.0' "$OUTDIR/ctsm60_params.noresm.c260406_BSW.nc" "$OUTDIR/ctsm60_params.noresm.c260406_BSW.nc"

echo "Wrote:"
ls -1 "$OUTDIR"/ctsm60_params.noresm.c260406_{SUC,WAT,BSW}.nc
