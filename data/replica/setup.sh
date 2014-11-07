#!/bin/bash

function die()
{
        echo $1 && exit 1
}

P4D_DIR=$1
if [ "$P4D_DIR" == "" ] ; then
        die "run with a p4d directory"
fi

export P4PORT=master:1666
export P4USER=super

PATH=$PATH:/opt/perforce/bin:/opt/perforce/sbin

# copy ssh keys to make scp from master possible
mkdir -p ~/.ssh && cp -r /vagrant_data/id_rsa* ~/.ssh && chmod go-rwx ~/.ssh/* && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
        && ssh-keyscan -t rsa master > ~/.ssh/known_hosts || die "failed to configure ssh keys"

# Step 3 Set the server id
# p4 serverid replica1 || die "failed to Step 0"

# Step 1 Boot-strap the replica server by checkpointing the master server, and restoring that checkpoint to the replica:
p4 admin checkpoint || die "failed to Step 1"
# (For a new setup, we can assume the checkpoint file is named checkpoint.1)

# Step 2 Move the checkpoint to the replica server's P4ROOT directory and replay the checkpoint:
scp master:/var/perforce/p4d/checkpoint.* /tmp || die "failed to Step 2 (scp checkpoint from master)"
p4d -r /var/perforce/p4d -jr /tmp/checkpoint.1 || die "failed to Step 2"

# Step 3 Copy the versioned files from the master server to the replica.
# Versioned files include both text (in RCS format, ending with ",v") and binary files (directories of individual binary files, each directory ending with ",d"). Ensure that you copy the text files in a manner that correctly translates line endings for the replica host's filesystem.
# If your depots are specified using absolute paths on the master, use the same paths on the replica. (Or use relative paths in the Map: field for each depot, so that versioned files are stored relative to the server's root.)

# Step 4 Contact Perforce Technical Support to obtain a duplicate of your master server license file. Copy the license file for the replica server to the replica server root directory.

# Step 5 To create a valid ticket file, use p4 login to connect to the master server and obtain a ticket on behalf of the replica server's service user. On the machine that will host the replica server, run:
# p4 -u service -p master:11111 login || die "failed to Step 5"

# Then move the ticket to the location that holds the P4TICKETS file for the replica server's service user.

# Start the replica server
p4d -r /var/perforce/p4d -In Replica1 -p 1666 -Lp4d.log -d

