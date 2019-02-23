#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}
./ibbot.rb -v --username $P123USR --password $P123PWD --import_pf PERSO --import_sim 1557921:93 --import_sim 1558659:5

