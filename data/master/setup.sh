#!/bin/bash

function die()
{
        echo $1 && exit 1
}

P4D_DIR="/var/perforce/p4d"
# make our data dir, run script, etc.
mkdir -p $P4D_DIR || die "failed to create p4d directory"

# set up p4d runner

# run it
/vagrant_data/run-p4d.sh $P4D_DIR
