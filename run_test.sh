#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

LOGFILE=test.log
./ibbot.rb -v --username $P123USR --password $P123PWD --testonly --logfile $LOGFILE

if [ $? -ne 0 ];then
    echo "Test failed"
    tail -20 $LOGFILE > part-${LOGFILE}
    cat part-${LOGFILE}
    mail -s "IBBOT tests failed" $P123MAIL < part-${LOGFILE}
    rm part-${LOGFILE}
fi

