#!/bin/bash
# Customize here the main script with your parameters

./extractpf.rb PRO
./extractpf.rb PERSO

./extractsim.rb 1557921

./genorders.rb PRO 1557921
./genorders.rb PERSO 1557921
