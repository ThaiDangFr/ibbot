#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

if [ $(date +%w) -gt 5 ] ||  [ $(date +%w) -lt 1 ]; then
    exit 0
fi


LOGFILE=perso.log
./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PERSO --import_sim 1559123:10 --import_sim 1575679:88 --logfile $LOGFILE --rebalance --commit

if [ $? -ne 0 ];then
    ./report.rb --email $P123MAIL --subject "IBBOT failed | $LOGFILE" --logfile $LOGFILE
fi
