#!/usr/bin/env python3
import shutil
from pathlib import Path

import netCDF4 as nc

BASE = Path('/cluster/home/rosief/git/RunScripts_Olivia/Jun26/amazon_ppe/clmparams/ctsm60_params.noresm.c260406.nc')
OUTDIR = BASE.parent

VARIANTS = {
    'SUC': ('sucsat_sf', 1.2),
    'WAT': ('watsat_sf', 1.2),
    'BSW': ('bsw_sf', 3.0),
}

if not BASE.exists():
    raise SystemExit(f'Missing base parameter file: {BASE}')

for tag, (varname, value) in VARIANTS.items():
    out = OUTDIR / f'ctsm60_params.noresm.c260406_{tag}.nc'
    shutil.copy2(BASE, out)

    with nc.Dataset(out, 'r+') as ds:
        if varname not in ds.variables:
            raise SystemExit(f"Variable '{varname}' not found in {out}")
        ds.variables[varname][...] = value

    print(f'Wrote {out} with {varname}={value}')
