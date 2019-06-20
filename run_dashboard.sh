#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

if [ $(date +%w) -gt 5 ] ||  [ $(date +%w) -lt 1 ]; then
    exit 0
fi


LOGFILE=dashboard.log
./dashboard.rb -v --username $P123USR --password $P123PWD --logfile $LOGFILE --rebalance --commit

if [ $? -ne 0 ];then
    ./report.rb --email $P123MAIL --subject "IBBOT failed | $LOGFILE" --logfile $LOGFILE
fi
