#!/bin/bash

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-download.sh --no-cache -O provisioning-download.sh
chmod 744 provisioning-download.sh
./provisioning-download.sh

./provisioning-generic.sh

