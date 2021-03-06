#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load modules if necessary
source $scriptdir/loadPlatformSpecific.sh preprocessing

#---------------------------#
#   Experiment variables    #
#---------------------------#

compset="FSPCAMm_AMIP"
experiment="abrupt4xCO2"
case="bf_"${compset}"_"$experiment

if [[ "$HOSTNAME" == "jollyjumper" ]]
then
	inputdir="/Users/bfildier/Data/preprocessed/"${case}"/day"
	inputdir_fx="/Users/bfildier/Data/preprocessed/allExperiments/fx"
elif [[ "$HOSTNAME" == "edison"* ]] || [[ "$HOSTNAME" == "cori"* ]]
then	
	inputdir=${scriptdir%\/*}"/preprocessed/"${case}"/day"
	inputdir_fx=${scriptdir%\/*}"/preprocessed/allExperiments/fx"
fi

areacellafile=${inputdir_fx}"/areacella_fx_CESM111-SPCAM20_allExperiments_r0i0p0.nc"

#---------------------------------------------------------------#
#    Compute area and number of rainy grid points               #
#---------------------------------------------------------------#

cd $inputdir

pr_ids="CRM_PREC_I90 CRM_PREC_I75 CRM_PREC_I50 CRM_PREC_I25 CRM_PREC_I10"
# pr_ids="CRM_PREC_I90"

for pr_id in `echo ${pr_ids}`
do
	id=`echo ${pr_id} | sed 's/_/-/g'`
	## Define new varids
	precfracid="PRECFRAC_"${pr_id#CRM_PREC_*}
	precareaid="PRECAREA_"${pr_id#CRM_PREC_*}
	echo 
	echo "------------------------------------------------------------"
	echo "     Computing ${precareaid} and ${precfracid} "
	echo "     for $compset and $experiment"
	echo "------------------------------------------------------------"
	for file in `ls ${id}_*`
	do
		## Define new files
		fileroot=${file#${id}*}
		precfracfile="PRECFRAC-"${pr_id#CRM_PREC_*}${fileroot}
		precareafile="PRECAREA-"${pr_id#CRM_PREC_*}${fileroot}
		echo 
		echo "    Creating $precfracfile"
		echo "     and     $precareafile"
		## Compute new variable values
		if [ -f ${inputdir}/"PRECT"${fileroot} ]
		then
			## Put PRECT and CRM_PREC in the same temp.nc file before computing PRECFRAC
			ncks -O $file temp.nc
			ncks -A "PRECT"${fileroot} temp.nc
			ncap -O -s "${precfracid}=PRECT/${pr_id}" temp.nc -v ${precfracfile}
			## Append areacella to temp.nc before computing PRECAREA
			ncks -A -v areacella ${areacellafile} temp.nc
			ncap -O -s "${precareaid}=PRECT/${pr_id}*areacella" temp.nc -v ${precareafile}
			## Delete temporary file
			rm temp.nc
		else
			echo "Error: file PRECT${fileroot} does not exist in $inputdir."
		fi
	done

done

cd -
