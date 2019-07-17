#!/bin/bash

################################
# Generic setup.               #
################################

# Enable https apt.
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
#software-properties-common
#!/bin/bash

local_ip=$(ifconfig | awk '/inet (10.165(\.[0-9]+)+)/ {print $2}')
kubectl="kubectl --kubeconfig=${HOME}/.kube/config-ibm"

# Get the IP of this node, in the VPN. (10.0.0.0/8).
distro=$(cat /etc/*-release | awk -F '=' '/^ID=/ {print $2}')
codename=$(cat /etc/*-release | awk -F '=' '/^VERSION_CODENAME=/ {print $2}')

if [ "$codename" == "" ]; then
	codename=$(cat /etc/*-release | awk -F '[=()]' '/^VERSION=/ {print $3}')
fi

function iex() {
	$1
}

BLACK='\033[0;30m'
DARK_GRAY='\033[1;30m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
LIGHT_GRAY='\033[0;37m'
WHITE='\033[1;37m'
#!/bin/bash

wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-master.sh --no-cache -O provisioning-master.sh
chmod 744 provisioning-master.sh

#wget https://raw.githubusercontent.com/Y-Less/provisioning/master/provisioning-client.sh --no-cache -O provisioning-client.sh
#chmod 744 provisioning-client.sh

################################
# Allow people root access.    #
################################
mkdir -p ~/.ssh

# Alex
# Also fails (with a message) when the file doesn't exist.
if ! grep -q 'AAAAC3NzaC1lZDI1NTE5AAAAIBUV3j21aQkdQ/Ix/WlGr7CkpXxbtzWx00lnkzefHbPI alex@y-less.com' ~/.ssh/authorized_keys; then
	echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUV3j21aQkdQ/Ix/WlGr7CkpXxbtzWx00lnkzefHbPI alex@y-less.com >> ~/.ssh/authorized_keys
fi

# TODO: Other SSH keys here.

################################
# Disable password access.     #
################################
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# One of these does it...
#service ssh restart
#service sshd restart
#/etc/init.d/ssh restart
systemctl restart ssh

################################
# Install kubernetes.          #
################################

# Add the kubernetes and docker repositories.
curl -fsSL https://download.docker.com/linux/$distro/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
echo "deb [arch=amd64] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update

# Install docker.
# "5:18.09.7~3-0~ubuntu-bionic" is optional, but will mean different servers get different versions.
apt-get install -y docker-ce=5:18.09.7~3-0~$distro-$codename

# Setup daemon.  Make docker use systemd for resource isolation.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# (Auto-)start the service.
mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Install kubernetes.
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
kubeadm config images pull

# Disable the swap, because kubernetes hates it for some reason.
swapoff -a

sysctl net.bridge.bridge-nf-call-iptables=1

