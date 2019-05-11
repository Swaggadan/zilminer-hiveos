#!/usr/bin/env bash

VERSION="1.8"

WALLET=0xYOURWALLETGOESHERE

LOGS="/var/log/miner/zil"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

source /etc/environment
export $(cat /etc/environment | grep -vE "^$|^#" | cut -d= -f1)

WORKER=$(cat /hive-config/rig.conf | grep WORKER_NAME= | cut -d '=' -f2 | sed 's/"//g')

[[ ! -d "$LOGS" ]] && mkdir "$LOGS"

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


NVIDIA=$(cat /run/hive/gpu-detect.json | grep -B1 '"brand": "nvidia",' | grep '"name"' | cut -f2 -d":" | sed 's/ "//g' | sed 's/",//g' | base64 -w 0)
#NVIDIA=""
AMD=$(cat /run/hive/gpu-detect.json | grep -B1 '"brand": "amd",' | grep '"name"' | cut -f2 -d":" | sed 's/ "//g' | sed 's/",//g' | base64 -w 0)

#JSON="{\"gpus\":\"$NVIDIA\",\"amd\":\"$AMD\",\"hostname\":\"$HOSTNAME\",\"rig_id\":\"$RIG_ID\",\"farm_id\":\"$FARM_ID\"}"

MINER=zilminer

[[ ! -z "$NVIDIA" && -f "$DIR/zilminer-cuda10" ]] && MINER=zilminer-cuda10

#remove cuda warning
[[ -z "$NVIDIA" ]] && NOCUDA=-G

#just for sure
pkill -9 $MINER

echo "Starting Zil $VERSION at $(dt)"
while true; do

	block=$(get_height)

	if [[ ${block} -lt  10 ]]; then
		echo "Too early only Block: $block"
		sleep 3500
	fi

	block=$(get_height)

	while [[ ${block} -lt 80 ]]; do
		echo "Still early, in the middle, Block: $block"
		sleep 600

		block=$(get_height)
	done

	while [[ ${block} -lt 90 ]]; do
		echo "Sleeping 120 sec. Block: $block"
		sleep 120

		block=$(get_height)
	done

	while [[ ${block} -lt 95 ]]; do
		echo "Sleeping 60 sec. Block: $block"
		sleep 60

		block=$(get_height)
	done

	while [[ ${block} -lt 97 ]]; do
		echo "Sleeping 30. Getting closer to switch Block: $block"
		sleep 30

		block=$(get_height)
	done

	while [[ ${block} -lt 98 ]]; do
		echo "Sleeping 15. Getting closer to switch Block: $block"
		sleep 15

		block=$(get_height)
	done

	while [[ ${block} -lt 99 ]]; do
		echo "Sleeping 5. Getting closer to switch Block: $block"
		sleep 5

		block=$(get_height)
	done

	echo "Stopping HiveOS miners..."
	cd $DIR
	miner stop
	wd stop

	# Random sleep
	#sleep $(( ( $RANDOM % 9 ) + 3 ))
	sleep 3

	echo "Mining Zil at $(dt), block: $block"
	${DIR}/${MINER} ${NOCUDA} --stdout --retry-delay 1 --max-submit 99 --nocolor --farm-recheck 2000 -P zil://${WALLET}.${WORKER}@mine.zilliqaminers.com:4202/api > ${LOGS}/zilminer.log &

	PID=$!

	echo "Sleeping 200. $MINER is running"
	sleep 200

	block=$(get_height)
	while [ $block -gt 90 ]; do
		echo "Sleeping 60. Long end blocks. Waiting to start the PoW window Block: $block"
		sleep 60

		block=$(get_height)
	done

	while [ $block -lt 1 ]; do
		if tail -10 ${LOGS}/zilminer.log | grep -q "ZIL PoW Window End"; then
			break
		fi
		echo "Sleeping 10. It is still working on the PoW block: $block"
		sleep 10

		block=$(get_height)
	done

	#block=$(get_height)
	echo "Killing zilminer at $(dt), we are at block: $block"
	#Kill miner
	#kill -2 $PID
	pkill -2 $MINER

	# Random sleep
	sleep $(( ( $RANDOM % 9 ) + 3 ))

	echo "Start HiveOS miners $(dt)..."
	wd start
	miner start

done
