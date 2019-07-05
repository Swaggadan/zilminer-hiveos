#!/usr/bin/env bash

# Check for multiple screens, if more than one found - kill all
# if [[ $(screen -list | grep '.zil' | wc -l) -gt 1 ]]; then 
#     for i in $(screen -list | grep '.zil' | awk '{print $1}'); do 
#         screen -X -S $i kill
#     done
# fi
screens=`screen -ls zil | grep -E "[0-9]+\.zil" | cut -d. -f1 | awk '{print $1}'`

# Check for multiple screens, if more than one found - kill all
if [[ `echo $screens | tr ' ' '\n' | wc -l` -gt 1 ]]; then 
    for pid in $screens; do
        # echo "Stopping screen session $pid"
        screen -S $pid -X quit
    done
fi

if [[ ! $(screen -list | grep ".zil") ]]; then
    cd /home/user/zil && screen -dmS zil ./zil-miner-hive.sh ${ZIL_USER}
fi
