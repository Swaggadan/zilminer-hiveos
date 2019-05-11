#!/bin/bash

cd /home/user/zil

wget -q --no-check-certificate https://www.pathtoyourzil-miner-hive.sh.com/zil-miner-hive-h.sh -O zil-miner-hive.sh
chmod +x zil-miner-hive.sh 

cd /root 
mkdir miner 
cd miner 
wget https://github.com/cryptowhizzard/zilminer-hiveos/releases/download/1.0/zil0.2.tar.gz -O zil0.2.tar.gz 
tar -zxvf zil0.2.tar.gz 
cd 0.2 
rm /usr/local/bin/kernels -rf
mv * /usr/local/bin

cd /home/user/zil
(screen -X -S zil kill || true) && screen -dmS zil ./zil-miner-hive.sh 
