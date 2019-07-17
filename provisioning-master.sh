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

################################
# Set up the master.           #
################################

# This outputs a command to use to connect other nodes to this one.  Example:
#
#   kubeadm join 10.4.58.1:6443 --token 6g7h8i.9j0kd5f1a2b3c4d5 \
#       --discovery-token-ca-cert-hash sha256:1a2b3c4d5f1a2b3c4d5f1a2b3c4d5f1a2b3c4d5f1a2b3c4d5f1a2b3c4d5f1a2b
#
# TODO: Make it use the IBM internal IP.
# `tail -2` outputs only the last two lines, which are the ones we want for slave connections.
echo

echo -e "${RED}################################"
echo -e "${RED}#      Connection string       #"
echo -e "${RED}################################"

echo -e "${BLUE}"

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${local_ip} | tail -2

echo -e "${LIGHT_GRAY}"

mkdir -p ~/.kube
yes | cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config-ibm

# Install nvidia drivers on all nodes.
wget https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/ubuntu/daemonset.yaml -O driver-installer.yaml
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/device-plugins/nvidia-gpu/daemonset.yaml -O device-plugin.yaml

awk 's{if(/\s*tolerations:/) s=0; else next} /\s*affinity:/{s=1;next}1' driver-installer.yaml > driver-installer-deafined.yaml
awk 's{if(/\s*tolerations:/) s=0; else next} /\s*affinity:/{s=1;next}1' device-plugin.yaml > device-plugin-deafined.yaml

# nvidia drivers.
iex "$kubectl create -f driver-installer-deafined.yaml"
iex "$kubectl create -f device-plugin-deafined.yaml"

# Flannel.
iex "$kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

# Dashboard.
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml"

# Metrics.
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/aggregated-metrics-reader.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-delegator.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-reader.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-apiservice.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-deployment.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-service.yaml"
iex "$kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/resource-reader.yaml"

cat > admin-user.yaml <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system


EOF

iex "$kubectl apply -f admin-user.yaml"

echo -e "${RED}################################"
echo -e "${RED}#      User token              #"
echo -e "${RED}################################"

echo -e "${BLUE}"

$kubectl -n kube-system describe secret $($kubectl -n kube-system get secret | awk '/admin-user-token/{print $1}') | awk '/^token:/{print $2}'

echo -e "${LIGHT_GRAY}"

echo -e "${RED}################################"
echo -e "${RED}#      Kube config             #"
echo -e "${RED}################################"

echo -e "${BLUE}"

cat ${HOME}/.kube/config-ibm

echo -e "${LIGHT_GRAY}"

printConfig="cat ${HOME}/.kube/config-ibm"
printUser="$kubectl -n kube-system describe secret $($kubectl -n kube-system get secret | awk '/admin-user-token/{print $1}') | awk '/^token:/{print $2}'"

