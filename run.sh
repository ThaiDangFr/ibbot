#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

trade() {
    pfname = $1
    simid = $2

    ./extractpf.rb ${pfname}
    ./extractsim.rb ${simid}
    ./genorders.rb ${pfname} ${simid}
    ./tradeorders.rb ${pfname} output/${pfname}-${simid}-orders.txt

    mkdir -p output/done
    mv output/*.* output/done/
}


trade PRO 1557921
trade PERSO 1557921
