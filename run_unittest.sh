#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

PFNAME=PERSO
./unittest.rb --username $P123USR --password $P123PWD --import_pf $PFNAME --import_sim 1004872:98 

