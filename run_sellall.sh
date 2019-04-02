#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

if [ $(date +%w) -gt 5 ] ||  [ $(date +%w) -lt 1 ]; then
    exit 0
fi

./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PERSO --commit
./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PRO --commit
