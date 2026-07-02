#!/bin/bash 

dosetup1=1 #do first part of setup
dosetup2=1 #do second part of setup (after first manual modifications)
dosetup3=0 #do second part of setup (after namelist manual modifications)
dosubmit=0 #do the submission stage! Before this step, set up to run on dedicated nodes!!
forcenewcase=1 #scurb all the old cases and start again
forcenewcode=0 #scrub old code and start again
doanalysis=0 #analyze output (not yet coded up)
numCPUs=0 #Specify number of cpus. 0: use default

module load NRIS/CPU
module load Python/3.12.3-GCCcore-13.3.0 

echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="rosief"
project='nn9560k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?), nn2345k: NorESM (EU projects), nn11118k: NorESM4CMIP7
machine='olivia'

#NorESM dir
noresmrepo="ctsm5.4.042_noresm_v2_smallpatches"
noresmversion="ctsm5.4.042_noresm_v2"
branch="terminatecohorts-stricter"

# aka where do you want the code and scripts to live?
workpath="/cluster/work/projects/nn9560k/$USER/" 

# some more derived path names to simplify scripts
scriptsdir=$workpath$noresmrepo/cime/scripts/

#case dir
casedir=$workpath$casename

#Download code and checkout externals
if [ $dosetup1 -eq 1 ] 
then
    echo $workpath
    cd $workpath

    if [[ $forcenewcode -eq 1 ]]
    then
        if [[ -d "$noresmrepo" ]] 
        then    
        echo "$workpath$noresmrepo exists on your filesystem. Removing it!"
        rm -rf $workpath$noresmrepo
        fi
    fi

    pwd
    #go to repo, or checkout code
    if [[ -d "$noresmrepo" ]] 
    then
        cd $noresmrepo
        echo "Already have NorESM repo"
    else
        echo "Cloning NorESM"
        
        git clone https://github.com/NorESMhub/CTSM/ $noresmrepo
        cd $noresmrepo
        git checkout $noresmversion      
        #sed -i 's/ccs_config_noresm0.0.56/ccs_config_noresm0.0.57/g' .gitmodules
        #echo "Updated .gitmodules to use ccs_config_noresm0.0.57:"
        #grep -i -n 'ccs_config_noresm0.0.57' .gitmodules            
        ./bin/git-fleximod update 
        cd src/fates
	git fetch origin
	git checkout origin/tiny-patch-fixes-part4
        #Update ccs_config for Olivia
        #cp /cluster/work/projects/nn9560k/agu002_old/NorESM11/ccs_config/machines/olivia/config_batch.xml ccs_config/machines/olivia/ 
    fi
fi

cd $noresmrepo
cd src/fates
git fetch origin
git checkout origin/$branch


#Make case
if [[ $dosetup2 -eq 1 ]] 
then
    echo $scriptsdir
    cd $scriptsdir
    ./create_test --xml-category aux_clm_noresm --xml-machine olivia  --project nn9560k -t $branch

#    ./create_test  ERS_D_Ld5.ne16pg3_ne16pg3_mtn14.NIHISTClm60Nor.olivia_intel.clm-FatesNoresm -t terminatecohorts-stricter2  --project nn9560k
    #-c ctsm5.4.042_noresm_v1 --baseline-root /cluster/work/projects/nn9560k/noresm_baselines/ctsm_develop/
fi

