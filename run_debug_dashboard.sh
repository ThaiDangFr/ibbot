#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}


./dashboard.rb -v --username $P123USR --password $P123PWD --rebalance --dev

