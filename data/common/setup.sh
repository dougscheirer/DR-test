#!/bin/bash
# setup.sh server-id

function die()
{
        echo $1 && exit 1
}

SERVERID=$1
if [ "$SERVERID" == "" ] ; then
	die "run with master or replica"
fi

P4D_DIR="/var/perforce/p4d"

# clean the data dir, start fresh
/vagrant_data/stop-p4d.sh
rm -rf $P4D_DIR

# make our data dir, run script, etc.
mkdir -p $P4D_DIR || die "failed to create p4d directory"

# dnsmasq config
echo -e "address=/master/192.168.33.10\naddress=/replica1/192.168.33.11" >> /etc/dnsmasq.conf && service dnsmasq restart || die "failed to configure replica1 dnsmasq"

# master or replica?
if [ "$1" == "master" ] ; then
   /vagrant_master/setup.sh $P4D_DIR
else 
   /vagrant_replica/setup.sh $P4D_DIR
fi

