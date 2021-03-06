#!/bin/bash

function die()
{
        echo $1 && exit 1
}

P4D_DIR=$1
if [ "$P4D_DIR" == "" ] ; then
	die "run with a p4d directory"
fi

P4PORT=localhost:1666
P4USER=super

# copy ssh keys to enable scp from master to replica
mkdir -p ~/.ssh && cp -r /vagrant_data/id_rsa* ~/.ssh && chmod go-rwx ~/.ssh/* && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys || die "failed to configure ssh keys"

# run the master server
/vagrant_data/run-p4d.sh $P4D_DIR

export PATH=$PATH:/opt/perforce/bin/
export P4PORT="localhost:1666"
export P4USER=super

p4 info || die "failed to get p4 info"

# set up default users, etc.
p4 user -o | p4 user -i
p4 protect -o | p4 protect -i
( p4 user -o service ; echo -e "\nType: service\n" ) | p4 user -i -f

#################################
#
# Begin replica setup on master
#
#################################

# Step 0 set the server id
p4 serverid "Master" || die "failed to Step 0"

# Step 1(a) make Replica1 a RO replica of Master on the vagrant host port of 1666
p4 configure set Replica1#P4TARGET=master:1666 || die "failed to Step 1(a)"

# Step 1(b) Set the Replica1 server to save the replica server's log file using a specified file name. Keeping the log names unique prevents problems when collecting data for debugging or performance tracking purposes.
p4 configure set Replica1#P4LOG=replica1Log.txt || die "failed to Step 1(b)"

# Step 2 Set the Replica1 server configurable to 1, which is equivalent to specifying the "-vserver=1" server startup option:
p4 configure set Replica1#server=1 || die "failed to Step 2"
# Step 3 To enable process monitoring, set Replica1's monitor configurable to 1:
p4 configure set Replica1#monitor=1 || die "failed to Step 3"

# Step 4 To handle the Replica1 replication process, configure the following three startup.n commands. (When passing multiple items separated by spaces, you must wrap the entire set value in double quotes.)
# The first startup process sets p4 pull to poll once every second for journal data only:
p4 configure set "Replica1#startup.1=pull -i 1" || die "failed to Step 4"

# The next two settings configure the server to spawn two p4 pull threads at startup, each of which polls once per second for archive data transfers.

p4 configure set "Replica1#startup.2=pull -u -i 1" || die "failed to Step 4"
p4 configure set "Replica1#startup.3=pull -u -i 1" || die "failed to Step 4"

# Each p4 pull -u command creates a separate thread for replicating archive data. Heavily-loaded servers might require more threads, if archive data transfer begins to lag behind the replication of metadata. To determine if you need more p4 pull -u processes, read the contents of the rdb.lbr table, which records the archive data transferred from the master Perforce server to the replica.
# To display the contents of this table when a replica is running, run:
# p4 -p replica:1666 pull -l

# Likewise, if you only need to know how many file transfers are active or pending, use p4 -p replica:22222 pull -l -s.
# If p4 pull -l -s indicates a large number of pending transfers, consider adding more "p4 pull -u" startup.n commands to address the problem.
# If a specific file transfer is failing repeatedly (perhaps due to unrecoverable errors on the master), you can cancel the pending transfer with p4 pull -d -f file -r rev, where file and rev refer to the file and revision number.
# Step 5 Set the db.replication (metadata access) and lbr.replication (depot file access) configurables to readonly:

p4 configure set Replica1#db.replication=readonly || die "failed to Step 5"
p4 configure set Replica1#lbr.replication=readonly || die "failed to Step 5" 

# Because this replica server is intended as a warm standby (failover) server, both the master server's metadata and its library of versioned depot files are being replicated. When the replica is running, users of the replica will be able to run commands that access both metadata and the server's library of depot files.

# Step 6 Create the service user:
# p4 user -f service || die "failed to Step 6" 

# The user specification for the service user opens in your default editor. Add the following line to the user specification:
# Type: service
# Save the user specification and exit your default editor.
# By default, the service user is granted the same 12-hour login timeout as standard users. To prevent the service user's ticket from timing out, create a group with a long timeout on the master server. In this example, the Timeout: field is set to two billion seconds, approximately 63 years:

cat << EOF | p4 group -i
Group:	service_group

MaxResults:	unset

MaxScanRows:	unset

MaxLockTime:	unset

PasswordTimeout:	unset

Subgroups:

Owners:

Users:          service

Timeout: 	9999999999999
EOF
if [ "$?" != "0" ] ; then
   die "failed to Step 6" 
fi

# For more details, seeTickets and timeouts for service users.
# Step 7 Set the service user protections to super in your protections table. (See Permissions for service users.) It is good practice to set the security level of all your Perforce Servers to at least 1 (preferably to 3, so as to require a strong password for the service user, and ideally to 4, to ensure that only authenticated service users may attempt to perform replica or remote depot transactions.)

(p4 protect -o; echo -e "   super group service_group * //...\n") | p4 protect -i

# p4 configure set security=4 || die "failed to Step 7" 
# p4 passwd || die "failed to Step 7" 

# Step 8 Set the Replica1 configurable for the serviceUser to service.
p4 configure set Replica1#serviceUser=service || die "failed to Step 8" 

# This step configures the replica server to authenticate itself to the master server as the service user; this is equivalent to starting p4d with the -u service option.

# Step 9 If the user running the replica server does not have a home directory, or if the directory where the default .p4tickets file is typically stored is not writable by the replica's Perforce server process, set the replica P4TICKETS value to point to a writable ticket file in the replica's Perforce server root directory:
p4 configure set "Replica1#P4TICKETS=/p4/replica/.p4tickets" || die "failed to Step 9"

