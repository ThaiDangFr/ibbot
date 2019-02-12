#!/bin/bash
# Customize here the main script with your parameters

./extractpf.rb PRO
./extractpf.rb PERSO

./extractsim.rb 1557921

./genorder.rb PRO 1557921
./genorder.rb PERSO 1557921
