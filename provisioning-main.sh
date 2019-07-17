#!/bin/bash

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-download.sh -O provisioning-download.sh
chmod 777 provisioning-download.sh
./provisioning-download.sh

./provisioning-generic.sh

