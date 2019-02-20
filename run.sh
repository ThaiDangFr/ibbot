#!/bin/bash
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

./extractpf.rb PRO
./extractpf.rb PERSO

./extractsim.rb 1557921

./genorders.rb PRO 1557921
./genorders.rb PERSO 1557921

./tradeorders.rb PRO output/PRO-1557921-orders.txt
./tradeorders.rb PERSO output/PERSO-1557921-orders.txt
