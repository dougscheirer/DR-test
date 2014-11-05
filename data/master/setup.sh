#!/bin/bash

function die()
{
        echo $1 && exit 1
}

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
p4 info || die "failed to get p4 info"

# set up users, etc.
p4 -u super user -o | p4 -u super user -i
p4 -u super protect -o | p4 -u super protect -i
( p4 -u super user -o service ; echo -e "\nType: service\n" ) | p4 -u super user -i -f
