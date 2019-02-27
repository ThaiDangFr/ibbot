#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

LOGFILE=perso.log
./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PERSO --import_sim 1557921:74 --import_sim 1558659:4 --import_sim 1559123:20 --logfile $LOGFILE --rebalance --commit

if [ $? -ne 0 ];then
    ./report.rb --email $P123MAIL --subject "IBBOT failed | $LOGFILE" --logfile $LOGFILE
fi
