#!/bin/bash

. ./provisioning-setup.sh

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
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${local_ip} | tail -2
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
iex "$kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml"

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

iex "$kubectl -n kube-system get secret" | awk '/admin-user-token/{print $1}'

$kubectl -n kube-system describe secret $($kubectl -n kube-system get secret | awk '/admin-user-token/{print $1}') | awk '/^token:/{print $2}'

