#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}
./report.rb --email $P123MAIL --subject "IBBOT report"


