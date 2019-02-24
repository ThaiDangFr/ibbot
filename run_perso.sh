#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}
./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PERSO --import_sim 1557921:74 --import_sim 1558659:4 --import_sim 1559123:20 --logfile perso.log --commit

