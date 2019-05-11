#!/usr/bin/env bash

source /etc/environment
export $(cat /etc/environment | grep -vE "^$|^#" | cut -d= -f1)

TAG="hid"

WORKER=$(cat /hive-config/rig.conf | grep WORKER_NAME= | cut -d '=' -f2 | sed 's/"//g')
RIG_ID=$(cat /hive-config/rig.conf | grep RIG_ID= | cut -d '=' -f2)
FARM_ID=$(cat /hive-config/rig.conf | grep FARM_ID= | cut -d '=' -f2)

echo "User: $TAG"

# We mount the logs of zilliqa on Ramdrive to avoid USB cranking
if ! grep -qs /logs /proc/mounts; then                                                                                                                                                        
echo "Mounting ramdrive"                                                                                                                                                                      
mkdir -p /logs                                                                                                                                                                                
mount -t tmpfs -o size=100m tmpfs /logs                                                                                                                                                       
fi

#old cleanup
sed -i "/zil-switcher/d" /etc/crontab
sed -i "/ZIL_USER/d" /hive/etc/environment
sed -i "/zil-monitor.sh/d" /hive/etc/crontab.root

# Environemnt config
sed -i "/ZIL_USER/d" /etc/environment
echo "ZIL_USER=${TAG}" >> /etc/environment

# Ensure crontab exists
sed -i "/zil-monitor.sh/d" /etc/crontab
echo "*/15 * * * * root /home/user/zil/zil-monitor.sh" >> /etc/crontab

# Monitor script
wget -q --no-check-certificate https://gist.githubusercontent.com/cryptowhizzard/e2bdc692512375440f8de8c949300914/raw/4c7ab696006ecf2d9927658ab80f7e939f5fb9ed/zil-monitor.sh -O zil-monitor.sh && chmod +x zil-monitor.sh

# default rig config
function get_height() {
    local block=''
    block=$(curl -k -s "https://nlpool.nl/images/zilheight.txt" | xargs | tail -c 3)

    if ! [[ "$block" =~ ^[0-9]+$ ]]; then
        block=$(curl -m 10 -s -d '{"id": "1","jsonrpc": "2.0","method": "GetBlockchainInfo","params": [""]}' -H "Content-Type: application/json" -X POST "https://api.zilliqa.com/" | awk -F "," '{print $4}' | awk -F ":" '{print $2}' | awk -F '"' '{print $2}' | xargs | tail -c 3)
    fi

    # remove leading zeroes
    block=${block#0}

    echo ${block}
}

function dt() {
    local dt=''
    dt=$(date '+%d/%m/%Y %H:%M:%S')
    echo ${dt}
}

API_KEY=""
WALLET=0x39cE119C46e5955e8e7fC5d1d22912DFe11CF0C5

MINER=/usr/local/bin/zilminer 

# if [[ ${NVIDIA_VERSION} == *"396"* ]]; then
#     MINER=/hive/miners/ethminer/zilminer/0.1.25-cuda92/zilminer

#     if [[ -f "zilminer92" ]]; then
#         MINER="./zilminer92"
#     fi
# fi

# Kill default
for pid in $(pidof zilminer); do
    kill -9 $pid
    sleep 1
done

# # Kill cuda92
# for pid in $(pidof zilminer92); do
#     kill -9 $pid
#     sleep 1
# done

# # Kill cuda92
# for pid in $(pidof zilminer10); do
#     kill -9 $pid
#     sleep 1
# done

#NVIDIA=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | base64 -w 0)
# NVIDIA=$(cat /run/hive/gpu-detect.json | grep -B1 '"brand": "nvidia",' | grep '"name"' | cut -f2 -d":" | sed 's/ "//g' | sed 's/",//g' | base64 -w 0)
NVIDIA=""
AMD=$(cat /run/hive/gpu-detect.json | grep -B1 '"brand": "amd",' | grep '"name"' | cut -f2 -d":" | sed 's/ "//g' | sed 's/",//g' | base64 -w 0)

JSON="{\"gpus\":\"$NVIDIA\",\"amd\":\"$AMD\",\"hostname\":\"$HOSTNAME\",\"rig_id\":\"$RIG_ID\",\"farm_id\":\"$FARM_ID\"}"

echo Starting at $(dt)
while true; do

    block=$(get_height)

    if [[ ! $(screen -list | grep ".miner") ]]; then
        cd /hive/bin && ./miner restart
    fi

    if [[ ${block} -lt  10 ]]; then
        echo "Too early only Block: $block"
        sleep 3500
    fi

    block=$(get_height)

    while [[ ${block} -lt 70 ]]; do
        echo "Still early, in the middle, Block: $block"
        sleep 600

        block=$(get_height)
    done

    while [[ ${block} -lt 90 ]]; do
        echo "Sleeping 90 sec. Block: $block"
        sleep 180

        block=$(get_height)
    done

    while [[ ${block} -lt 95 ]]; do
        echo "Sleeping 60 sec. Block: $block"
        sleep 30

        block=$(get_height)
    done

    while [[ ${block} -lt 97 ]]; do
        echo "Sleeping 30. Getting closer to switch Block: $block"
        sleep 5

        block=$(get_height)
    done

    while [[ ${block} -lt 98 ]]; do
        echo "Sleeping 10. Getting closer to switch Block: $block"
        sleep 3

        block=$(get_height)
    done

    # Random sleep
    sleep $(( ( RANDOM % 9 )  + 1 ))

    echo Mining ZIL at $(dt)

    echo "Close, turning it off and starting other miner at block: $block"
    cd /home/user/zil && miner stop
    sleep 3

    COUNTER=1
    while IFS= read -r line
    do
       IP=$(echo ${line} | awk -F" " '{print $1}')
       GPUS=$(echo ${line} | awk -F" " '{print $2}' | sed 's/,/ /g')

       if [[ -z "$NVIDIA" ]]; then
           ${MINER} --farm-recheck 2000 -P zil://${WALLET}.$HOSTNAME@dimitry.cryptowhizzard.com:4202/api > /logs/zilminer.log 2>&1 &
       else
           ${MINER} --farm-recheck 2000 -P zil://${WALLET}.$HOSTNAME@dimitry.cryptowhizzard.com:4202/api > /logs/zilminer.log 2>&1 &
       fi
       
       let COUNTER++
    done < <(printf '%s\n' "${RESPONSE}")

    echo "Zilminer is running, sleeping 240"
    sleep 240

    block=$(get_height)
    while [ $block -gt 90 ]; do
        echo "long end blocks. waiting to start the PoW window block: $block"
        sleep 60

        block=$(get_height)
    done

    if [ ${block} -lt  1 ]; then
        echo "its still working on the PoW block: $block"
        sleep 90
    fi

    block=$(get_height)
    echo "killing zilminer now, we are at block: $block"

    # Kill default
    for pid in $(pidof zilminer); do
        kill -9 $pid
        sleep 1
    done

    sleep 1

    echo "Restart default HiveOS miner $(dt)"
    cd /home/user/zil && miner start
done
