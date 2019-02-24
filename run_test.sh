#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}
./ibbot.rb -v --username $P123USR --password $P123PWD --testonly #--logfile perso.log 

