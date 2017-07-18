#!/bin/bash

RPM=${RPM:-"/mswg/release/storage/ceph/rpm-v12.0.3-1967-gd6d04f7"}
GPG=${GPG:-"${RPM}/release.asc"}
HOSTS=${HOSTS:-$@}
PDSH_HOSTS=${HOSTS// /,}
PUBLIC_NETWORK=${PUBLIC_NETWORK:-"1.1.1.2/24"}
CLUSTER_NETWORK=${CLUSTER_NETWORK:-$PUBLIC_NETWORK}
MONITORS=$( echo $HOSTS | cut -d' ' -f1 )

function kill_process()
{
	local name=$1

	sudo pdsh -w $PDSH_HOSTS pkill -9 $name > /dev/null 2>&1
}

echo "RPM $RPM"
echo "GPG $GPG"
echo "Monitors $MONITORS"
echo "Public network: $PUBLIC_NETWORK"
echo "Cluster network: $CLUSTER_NETWORK"


sudo pdsh -w $PDSH_HOSTS systemctl start ceph.target  > /dev/null 2>&1
kill_process ceph-osd
kill_process ceph-mon
kill_process ceph-mgr

ceph-deploy purge $HOSTS
ceph-deploy purgedata $HOSTS
ceph-deploy forgetkeys
pdsh -w $PDSH_HOSTS ceph-deploy --overwrite-conf install --repo-url=file://${RPM}  --gpg-url=file://${GPG} `hostname`
ceph-deploy purge $HOSTS
ceph-deploy new --cluster-network=${CLUSTER_NETWORK} --public-network=${PUBLIC_NETWORK} ${MONITORS}
sed -i -e 's/cephx/none/g' ceph.conf
ceph-deploy --overwrite-conf mon create-initial
ceph-deploy gatherkeys ${MONITORS}
ceph-deploy --overwrite-conf $HOSTS
