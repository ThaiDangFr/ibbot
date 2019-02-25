#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

LOGFILE=test.log
./ibbot.rb -v --username $P123USR --password $P123PWD --testonly --logfile $LOGFILE

if [ $? -ne 0 ];then
    ./report.rb --email $P123MAIL --subject "IBBOT tests failed | $LOGFILE" --logfile $LOGFILE
fi

