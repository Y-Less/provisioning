#!/bin/bash

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-generic.sh --no-cache -O provisioning-generic.sh
chmod 744 provisioning-generic.sh

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-setup.sh --no-cache -O provisioning-setup.sh
chmod 744 provisioning-setup.sh

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-master.sh --no-cache -O provisioning-master.sh
chmod 744 provisioning-master.sh

#wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-client.sh --no-cache -O provisioning-client.sh
#chmod 744 provisioning-client.sh

