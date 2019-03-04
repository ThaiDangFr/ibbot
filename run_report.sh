#!/bin/bash -l
# Customize here the main script with your parameters

export scriptPath=$(dirname $0)
cd ${scriptPath}

if [ $(date +%w) -gt 5 ] ||  [ $(date +%w) -lt 1 ]; then
    exit 0
fi

./report.rb --email $P123MAIL --subject "IBBOT report"


