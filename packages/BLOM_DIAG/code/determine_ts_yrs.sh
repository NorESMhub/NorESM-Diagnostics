#!/bin/bash

# BLOM DIAGNOSTICS package: determine_ts_yrs.sh
# PURPOSE: determine first and last years of time series (only if TRENDS_ALL=1)
# Johan Liakka, NERSC; Dec 2017
# Yanchun He, NERSC; Jun 2020

# Input arguments:
#  $casename  simulation name
#  $pathdat   history file directory

casename=$1
pathdat=$2

echo " "
echo "-----------------------"
echo "determine_ts_yrs.sh"
echo "-----------------------"
echo "Input arguments:"
echo " casename = $casename"
echo " pathdat  = $pathdat"
echo " "
echo "Searching for annual history files..."

# Determine file tag
#filetag=$(find $pathdat \( -name "${casename}.blom.*.nc" -or \
            #-name "${casename}.micom.*.nc" \) -print -quit | \
            #head -1 |awk -F/ '{print $NF}' |awk -F. '{print $(NF-3)}')
for ocn in blom micom
do
    nmatch=$(find $pathdat -name "${casename}.${ocn}.*.nc" -print -quit 2>/dev/null |wc -l)
    [ $nmatch -ge 1 ] && filetag=$ocn && break
done
[ -z $filetag ] && echo "** NO ocean data found, EXIT ... **" && exit 1

file_head=$casename.$filetag.hy.
file_prefix=$pathdat/$file_head
first_file=`ls ${file_prefix}* | head -n 1`
last_file=`ls ${file_prefix}* | tail -n 1`
if [ -z $first_file ]; then
    echo "Found no annual history files in $pathdat"
    echo "Searcing for monthly history files"
    file_head=$casename.$filetag.hm.
    file_prefix=$pathdat/$file_head
    first_file=`ls ${file_prefix}* | head -n 1`
    last_file=`ls ${file_prefix}* | tail -n 1`
    if [ -z $first_file ]; then
        echo "ERROR: found no monthly history files in $pathdat"
        echo "*** EXITING THE SCRIPT ***"
        exit 1
    else
        fyr_prnt_ts=`echo $first_file | rev | cut -c 7-10 | rev`
        first_yr_ts=`echo $fyr_prnt_ts | sed 's/^0*//'`
        lyr_prnt_ts=`echo $last_file | rev | cut -c 7-10 | rev`
        last_yr_ts=`echo $lyr_prnt_ts | sed 's/^0*//'`
        # Check that last file is a december file (for a full year)
        if [ ! -f $pathdat/${file_head}${lyr_prnt_ts}-12.nc ]; then
            let "last_yr_ts = $last_yr_ts - 1"
            lyr_prnt_ts=`printf "%04d" ${last_yr_ts}`
        fi
        if [ $first_yr_ts -eq $last_yr_ts ]; then
            echo "ERROR: first and last year in $casename are identical: cannot compute trends"
            echo "*** EXITING THE SCRIPT ***"
            exit 1
        fi
    fi
else
    fyr_prnt_ts=`echo $first_file | rev | cut -c 4-7 | rev`
    first_yr_ts=`echo $fyr_prnt_ts | sed 's/^0*//'`
    lyr_prnt_ts=`echo $last_file | rev | cut -c 4-7 | rev`
    last_yr_ts=`echo $lyr_prnt_ts | sed 's/^0*//'`
    if [ $first_yr_ts -eq $last_yr_ts ]; then
        echo "ERROR: first and last year in $casename are identical: cannot compute trends"
        echo "*** EXITING THE SCRIPT ***"
        exit 1
    fi
fi
echo $first_yr_ts > $WKDIR/attributes/ts_yrs_${casename}
echo $last_yr_ts >> $WKDIR/attributes/ts_yrs_${casename}

