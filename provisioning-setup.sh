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

