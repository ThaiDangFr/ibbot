#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

trade() {
    pfname=$1
    simid=$2

    ./extractpf.rb ${pfname}
    ./extractsim.rb ${simid}
    ./genorders.rb ${pfname} ${simid}

    if [ "$DEBUG" != "1" ]; then
	./tradeorders.rb ${pfname} output/${pfname}-${simid}-orders.txt
    else
	echo "DEBUG mode : tradeorders.rb not executed"
    fi

    mkdir -p output/done
    mv output/*.* output/done/
}

if [ "$DEBUG" == "1" ]; then
    echo "Running in debugging mode"
    set -x
fi

trade PRO 1557921
