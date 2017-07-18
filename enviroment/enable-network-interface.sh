#!/bin/bash

INTERFACE=${1:-"ens8f0"}
BASE_IP=${2:-"1.1.1"}
SUBNET_BITS=${3:-"24"}
CONF_FILE="/etc/sysconfig/network-scripts/ifcfg-$INTERFACE"

if $( ibdev2netdev | grep ${INTERFACE}); then
	echo "ERROR: Interface ${INTERFACE} is not found"
	exit 1
fi

base=${HOSTNAME%%.*}
id=${base##*0}
ip="${BASE_IP}.${id}"

echo "Host $HOSTNAME"
echo "ID $id"
echo "Interface $INTERFACE"
echo "IPv4 $ip"
echo "Subnet bits $SUBNET_BITS"

ifconfig ${INTERFACE} down
ifconfig ${INTERFACE} "${ip}/${SUBNET_BITS}" up
ifconfig  ${INTERFACE}
ibdev2netdev | grep  ${INTERFACE}

cat << EOF > $CONF_FILE
DEVICE=${INTERFACE}
IPADDR=${ip}
NETMASK=255.255.0.0
NETWORK=11.130.55.1
BROADCAST=${ip}
ONBOOT=yes
BOOTPROTO=none
USERCTL=no
EOF

ipcalc -p  "${ip}/${SUBNET_BITS}" >> $CONF_FILE
ipcalc -n  "${ip}/${SUBNET_BITS}" >> $CONF_FILE
