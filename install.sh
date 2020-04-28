#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=6
BACKTITLE="MininCore Setup Wizard"
TITLE="MininCore"
MENU="Choose one of the following options:"

OPTIONS=(1 "Install New MiningCore Server"
         2 "Install MininCore UI"

	 )


CHOICE=$(whiptail --clear\
		--backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            echo Starting the install process.
echo Checking and installing VPS server prerequisites. Please wait.
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(swapon -s)
if [[ "$PHYMEM" -lt "2" && -z "$SWAP" ]];
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM, creating 2G swap file.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}The server running with at least 2G of RAM, or SWAP exists.${NC}"
fi
if [[ $(lsb_release -d) != *18.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
clear
sudo apt update
sudo apt-get -y upgrade
sudo apt-get install git -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
sudo apt-get install libqt4-dev libprotobuf-dev protobuf-compiler -y
clear
echo VPS Server prerequisites installed.
sleep 10


echo Install the ASP.NET Core runtime.
sudo wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb -y
sudo add-apt-repository universe -y
sudo apt-get update -y
sudo apt-get install apt-transport-https -y
sudo apt-get update -y
sudo apt-get install dotnet-sdk-3.1 -y
echo Install the ASP.NET Core runtime completed.
sleep 10


echo Install the .NET Core runtime
sudo add-apt-repository universe -y
sudo apt-get update -y
sudo apt-get install apt-transport-https -y
sudo apt-get update -y
sudo apt-get install dotnet-runtime-3.1 -y
echo Install the ASP.NET Core runtime completed.
sleep 10


echo Installing PostgreSQL.
sudo apt update -y
sudo apt install postgresql postgresql-contrib -y
echo Installing PostgreSQL complete.
sleep 10




sudo -u postgres psql << EOF
CREATE DATABASE miningcore;
create user miningcore with encrypted password 'miningcore';
ALTER ROLE miningcore REPLICATION;
ALTER ROLE miningcore Superuser;
ALTER ROLE miningcore Create role;
ALTER ROLE miningcore Create DB;
ALTER ROLE miningcore Bypass RLS;
EOF



echo Importing MiningCore database template.
sudo wget https://raw.githubusercontent.com/coinfoundry/miningcore/master/src/Miningcore/Persistence/Postgres/Scripts/createdb.sql
sudo -u postgres psql miningcore < 'createdb.sql'
echo Importing MiningCore database template complete.
sleep 10


echo Now lets create our user and not use the root account.
sudo adduser pool
echo Please input your pool users password you wish to use.
sudo psswd pool
usermod -aG sudo pool
echo Now lets create our user and not use the root account complete.
sleep 10


echo Now lets compile the source under our new user.
sudo apt-get -y install dotnet-sdk-2.2 git cmake build-essential libssl-dev pkg-config libboost-all-dev libsodium-dev libzmq5
cd /home/pool/
sudo git clone https://github.com/akshaynexus/miningcore.git
cd miningcore/src/Miningcore
dotnet publish -c Release --framework netcoreapp3.1  -o ../../build
echo Compile completed.
sleep 10



echo Creating config file.
cd ../../build
sudo mkdir -p /home/pool/miningcore/build/config.json && touch /home/pool/miningcore/build/config.json


sudo cat << EOF > /home/pool/miningcore/build/config.json
{
    "logging": {
        "level": "info",
        "enableConsoleLog": true,
        "enableConsoleColors": true,
        // Log file name (full log) - can be null in which case log events are written to console (stdout)
        "logFile": "core.log",
        // Log file name for API-requests - can be null in which case log events are written to either main logFile or console (stdout)
        "apiLogFile": "api.log",
        // Folder to store log file(s)
        "logBaseDirectory": "/path/to/logs", // or c:\path\to\logs on Windows
        // If enabled, separate log file will be stored for each pool as <pool id>.log
        // in the above specific folder.
        "perPoolLogFile": false
    },
    "banning": {
        // "integrated" or "iptables" (linux only - not yet implemented)
        "manager": "integrated",
        "banOnJunkReceive": true,
        "banOnInvalidShares": false
    },
    "notifications": {
        "enabled": true,
        "email": {
            "host": "smtp.example.com",
            "port": 587,
            "user": "user",
            "password": "password",
            "fromAddress": "info@yourpool.org",
            "fromName": "pool support"
        },
        "admin": {
            "enabled": false,
            "emailAddress": "user@example.com",
            "notifyBlockFound": true
        }
    },
    // Where to persist shares and blocks to
    "persistence": {
        // Persist to postgresql database
        "postgres": {
            "host": "127.0.0.1",
            "port": 5432,
            "user": "miningcore",
            "password": "yourpassword",
            "database": "miningcore"
        }
    },
    // Generate payouts for recorded shares and blocks
    "paymentProcessing": {
        "enabled": true,
        // How often to process payouts, in milliseconds
        "interval": 600,
        // Path to a file used to backup shares under emergency conditions, such as
        // database outage
        "shareRecoveryFile": "recovered-shares.txt"
    },
    // API Settings
    "api": {
        "enabled": true,
        // Binding address (Default: 127.0.0.1)
        "listenAddress": "127.0.0.1",
        // Binding port (Default: 4000)
        "port": 4000,
        // IP address whitelist for requests to Prometheus Metrics (default 127.0.0.1)
        "metricsIpWhitelist": [],
        // Limit rate of requests to API on a per-IP basis
        "rateLimiting": {
            "disabled": false, // disable rate-limiting all-together, be careful
            // override default rate-limit rules, refer to https://github.com/stefanprodan/AspNetCoreRateLimit/wiki/IpRateLimitMiddleware#defining-rate-limit-rules
            "rules": [
                {
                    "Endpoint": "*",
                    "Period": "1s",
                    "Limit": 5
                }
            ],
            // List of IP addresses excempt from rate-limiting (default: none)
            "ipWhitelist": []
        }
    },
    "pools": [
        {
            // DON'T change the id after a production pool has begun collecting shares!
            "id": "dash1",
            "enabled": true,
            "coin": "dash",
            // Address to where block rewards are given (pool wallet)
            "address": "yiZodEgQLbYDrWzgBXmfUUHeBVXBNr8rwR",
            // Block rewards go to the configured pool wallet address to later be paid out
            // to miners, except for a percentage that can go to, for examples,
            // pool operator(s) as pool fees or or to donations address. Addresses or hashed
            // public keys can be used. Here is an example of rewards going to the main pool
            // "op"
            "rewardRecipients": [
                {
                    // Pool wallet
                    "address": "yiZodEgQLbYDrWzgBXmfUUHeBVXBNr8rwR",
                    "percentage": 1.5
                }
            ],
            // How often to poll RPC daemons for new blocks, in milliseconds
            "blockRefreshInterval": 400,
            // Some miner apps will consider the pool dead/offline if it doesn't receive
            // anything new jobs for around a minute, so every time we broadcast jobs,
            // set a timeout to rebroadcast in this many seconds unless we find a new job.
            // Set to zero to disable. (Default: 0)
            "jobRebroadcastTimeout": 10,
            // Remove workers that haven't been in contact for this many seconds.
            // Some attackers will create thousands of workers that use up all available
            // socket connections, usually the workers are zombies and don't submit shares
            // after connecting. This features detects those and disconnects them.
            "clientConnectionTimeout": 600,
            // If a worker is submitting a high threshold of invalid shares, we can
            // temporarily ban their IP to reduce system/network load.
            "banning": {
                "enabled": true,
                // How many seconds to ban worker for
                "time": 600,
                // What percent of invalid shares triggers ban
                "invalidPercent": 50,
                // Check invalid percent when this many shares have been submitted
                "checkThreshold": 50
            },
            // Each pool can have as many ports for your miners to connect to as you wish.
            // Each port can be configured to use its own pool difficulty and variable
            // difficulty settings. 'varDiff' is optional and will only be used for the ports
            // you configure it for.
            "ports": {
                // Binding port for your miners to connect to
                "3052": {
                    // Binding address (Default: 127.0.0.1)
                    "listenAddress": "0.0.0.0",
                    // Pool difficulty
                    "difficulty": 0.02,
                    // TLS/SSL configuration
                    "tls": false,
                    "tlsPfxFile": "/var/lib/certs/mycert.pfx",
                    // Variable difficulty is a feature that will automatically adjust difficulty
                    // for individual miners based on their hash rate in order to lower
                    // networking overhead
                    "varDiff": {
                        // Minimum difficulty
                        "minDiff": 0.01,
                        // Maximum difficulty. Network difficulty will be used if it is lower than
                        // this. Set to null to disable.
                        "maxDiff": null,
                        // Try to get 1 share per this many seconds
                        "targetTime": 15,
                        // Check to see if we should retarget every this many seconds
                        "retargetTime": 90,
                        // Allow time to very this % from target without retargeting
                        "variancePercent": 30,
                        // Do not alter difficulty by more than this during a single retarget in
                        // either direction
                        "maxDelta": 500
                    }
                }
            },
            // Recommended to have at least two daemon instances running in case one drops
            // out-of-sync or offline. For redundancy, all instances will be polled for
            // block/transaction updates and be used for submitting blocks. Creating a backup
            // daemon involves spawning a daemon using the "-datadir=/backup" argument which
            // creates a new daemon instance with it's own RPC config. For more info on this,
            // visit: https:// en.bitcoin.it/wiki/Data_directory and
            // https:// en.bitcoin.it/wiki/Running_bitcoind
            "daemons": [
                {
                    "host": "127.0.0.1",
                    "port": 15001,
                    "user": "user",
                    "password": "pass",
                    // Enable streaming Block Notifications via ZeroMQ messaging from Bitcoin
                    // Family daemons. Using this is highly recommended. The value of this option
                    // is a string that should match the value of the -zmqpubhashblock parameter
                    // passed to the coin daemon. If you enable this, you should lower
                    // 'blockRefreshInterval' to 1000 or 0 to disable polling entirely.
                    "zmqBlockNotifySocket": "tcp://127.0.0.1:15101",
                    // Enable streaming Block Notifications via WebSocket messaging from Ethereum
                    // family Parity daemons. Using this is highly recommended. The value of this
                    // option is a string that should  match the value of the --ws-port parameter
                    // passed to the parity coin daemon. When using --ws-port, you should also
                    // specify --ws-interface all and
                    // --jsonrpc-apis "eth,net,web3,personal,parity,parity_pubsub,rpc"
                    // If you enable this, you should lower 'blockRefreshInterval' to 1000 or 0
                    // to disable polling entirely.
                    "portWs": 18545,
                }
            ],
            // Generate payouts for recorded shares
            "paymentProcessing": {
                "enabled": true,
                // Minimum payment in pool-base-currency (ie. Bitcoin, NOT Satoshis)
                "minimumPayment": 0.01,
                "payoutScheme": "PPLNS",
                "payoutSchemeConfig": {
                    "factor": 2.0
                }
            }
        }
    ]
}
EOF

cd /home/pool/miningcore/build/
dotnet Miningcore.dll -c config.json
;;
	    
    
2)



         

echo MinningCore install complete.             ;;


esac