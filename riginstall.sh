#!/bin/bash

cd /home/user/zil

wget -q --no-check-certificate https://gist.githubusercontent.com/cryptowhizzard/a7ab9e6453ac83dc090c5965a1e6c49a/raw/1c2ebd180e4a3a28756d05a4a613c67b6add3759/zil-miner-hive-h.sh -O zil-miner-hive.sh
chmod +x zil-miner-hive.sh 

cd /root 
mkdir miner 
cd miner 
wget http://zilliqa.nlpool.nl:81/zil0.2.tar.gz -O zil0.2.tar.gz 
tar -zxvf zil0.2.tar.gz 
cd 0.2 
rm /usr/local/bin/kernels -rf
mv * /usr/local/bin

cd /home/user/zil
(screen -X -S zil kill || true) && screen -dmS zil ./zil-miner-hive.sh 
