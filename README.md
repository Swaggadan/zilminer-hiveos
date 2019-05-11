# zilminer-hiveos
Zilminer for HiveOS

To start zilliqa mining with your HiveOS please do the following:

A : Download riginstall.sh script and put it somewhere accessible for your rig so you can access it later for download, for example https://www.yourwebsiteordropbox.com/riginstall.sh

B : Download zil-miner-hive.sh, edit the wallet= line and put your zilliqawallet address there and put the file somewhere where you can download it. Edit A above (Riginstall.sh) to reflect the path!

C : In HiveOS select the rigs to install and do "Execute command" like :

wget -q https://www.yourwebsiteordropbox.com/riginstall.sh -O riginstall.sh && chmod +x riginstall.sh && ./riginstall.sh
If all goes OK you will see a blue command after 30 seconds or so. 

To verify all is working ok, when the Epoch has passed ( once in 2.5 hours ) you can again do "execute command" like:
cat /logs/zilminer.log. When you click on it you can see the output of zilminer.log.

For any questions contact us at Telegram or Discord.
