#!/bin/bash

RPM=${RPM:-"/mswg/release/storage/ceph/rpm-v12.0.3-1967-gd6d04f7"}
GPG=${GPG:-"${RPM}/release.asc"}
HOSTS=${HOSTS:-$@}
PDSH_HOSTS=${HOSTS// /,}
MONITORS=$( echo $HOSTS | cut -d' ' -f1 )

function kill_process()
{
	local name=$1

	sudo pdsh -w $PDSH_HOSTS pkill -9 $name > /dev/null 2>&1 ||:
}

function relase_yum_lock()
{
	kill_process yum
	sudo pdsh -w $PDSH_HOSTS rm -f /var/run/yum.pid > /dev/null 2>&1 ||:
}

function get_full_ip4_by_interface()
{
	local interface=$1
	ip addr show ${interface} | grep "inet\b" | awk '{print $2}'
}

function get_ip_by_interface()
{
	local interface=$1
	get_full_ip4_by_interface $interface |  cut -d/ -f1
}

function get_rdma_interface()
{
	ibdev2netdev | grep Up | head -1 | cut -d" " -f5
}

RDMA_INTERFACE=${RDMA_INTERFACE:-$(get_rdma_interface)}
IPv4=$(get_ip_by_interface $RDMA_INTERFACE)
PUBLIC_NETWORK=${PUBLIC_NETWORK:-$(get_full_ip4_by_interface $RDMA_INTERFACE)}
CLUSTER_NETWORK=${CLUSTER_NETWORK:-$PUBLIC_NETWORK}

echo "RPM $RPM"
echo "GPG $GPG"
echo "Monitors $MONITORS"
echo "RDMA interface: $RDMA_INTERFACE"
echo "IPv4: $IPv4"
echo "Public network: $PUBLIC_NETWORK"
echo "Cluster network: $CLUSTER_NETWORK"


sudo pdsh -w $PDSH_HOSTS systemctl start ceph.target  > /dev/null 2>&1 ||:
kill_process ceph-osd
kill_process ceph-mon
kill_process ceph-mgr
relase_yum_lock

ceph-deploy purge $HOSTS
ceph-deploy purgedata $HOSTS
ceph-deploy forgetkeys
pdsh -w $PDSH_HOSTS 'ceph-deploy --overwrite-conf install --repo-url=file://${RPM}  --gpg-url=file://${GPG} `hostname -s `'
ceph-deploy purge $HOSTS
ceph-deploy new --cluster-network=${CLUSTER_NETWORK} --public-network=${PUBLIC_NETWORK} ${MONITORS}
sed -i -e 's/cephx/none/g' ceph.conf
ceph-deploy --overwrite-conf mon create-initial
ceph-deploy gatherkeys ${MONITORS}
ceph-deploy --overwrite-conf $HOSTS
