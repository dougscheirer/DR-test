#!/bin/bash
# setup.sh server-id

function die()
{
        echo $1 && exit 1
}

SERVERID=$1
P4D_DIR="/var/perforce/p4d"

# clean the data dir, start fresh
/vagrant_data/stop-p4d.sh
rm -rf $P4D_DIR

# make our data dir, run script, etc.
mkdir -p $P4D_DIR || die "failed to create p4d directory"

# run it
/vagrant_data/run-p4d.sh $P4D_DIR

export PATH=$PATH:/opt/perforce/bin/
export P4PORT="localhost:1666"
export P4USER=super

p4 info || die "failed to get p4 info"
p4 serverid $SERVERID 

# set up users, etc.
p4 user -o | p4 user -i
p4 protect -o | p4 protect -i
( p4 user -o service ; echo -e "\nType: service\n" ) | p4 user -i -f

# dnsmasq config
echo -e "address=/master/192.168.33.10\naddress=/replica1/192.168.33.11" >> /etc/dnsmasq.conf && service dnsmasq restart || die "failed to configure replica1 dnsmasq"

# master or replica?
if [ "$1" == "master" ] ; then
   /vagrant_master/setup.sh
else
   /vagrant_replica/setup.sh
fi

