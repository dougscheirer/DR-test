#!/bin/bash

function die()
{
        echo $1 && exit 1
}

P4PORT=localhost:1666
P4USER=super

# Step 1(a) make Replica1 a RO replica of Master on the vagrant host port of 6661
p4 configure set Replica1#P4TARGET=master:6661 || die "failed to Step 1(a)"

# Step 1(b) Set the Replica1 server to save the replica server's log file using a specified file name. Keeping the log names unique prevents problems when collecting data for debugging or performance tracking purposes.
p4 configure set Replica1#P4LOG=replica1Log.txt

# Step 2 Set the Replica1 server configurable to 1, which is equivalent to specifying the "-vserver=1" server startup option:
p4 configure set Replica1#server=1
# To enable process monitoring, set Replica1's monitor configurable to 1:
p4 configure set Replica1#monitor=1
# To handle the Replica1 replication process, configure the following three startup.n commands. (When passing multiple items separated by spaces, you must wrap the entire set value in double quotes.)
# The first startup process sets p4 pull to poll once every second for journal data only:
p4 configure set "Replica1#startup.1=pull -i 1"

# The next two settings configure the server to spawn two p4 pull threads at startup, each of which polls once per second for archive data transfers.

p4 configure set "Replica1#startup.2=pull -u -i 1"
p4 configure set "Replica1#startup.3=pull -u -i 1"
# Each p4 pull -u command creates a separate thread for replicating archive data. Heavily-loaded servers might require more threads, if archive data transfer begins to lag behind the replication of metadata. To determine if you need more p4 pull -u processes, read the contents of the rdb.lbr table, which records the archive data transferred from the master Perforce server to the replica.
# To display the contents of this table when a replica is running, run:
p4 -p replica:22222 pull -l
# Likewise, if you only need to know how many file transfers are active or pending, use p4 -p replica:22222 pull -l -s.
# If p4 pull -l -s indicates a large number of pending transfers, consider adding more "p4 pull -u" startup.n commands to address the problem.
# If a specific file transfer is failing repeatedly (perhaps due to unrecoverable errors on the master), you can cancel the pending transfer with p4 pull -d -f file -r rev, where file and rev refer to the file and revision number.
# Set the db.replication (metadata access) and lbr.replication (depot file access) configurables to readonly:

p4 configure set Replica1#db.replication=readonly
p4 configure set Replica1#lbr.replication=readonly

# Because this replica server is intended as a warm standby (failover) server, both the master server's metadata and its library of versioned depot files are being replicated. When the replica is running, users of the replica will be able to run commands that access both metadata and the server's library of depot files.

# Create the service user:
# p4 user -f service

# The user specification for the service user opens in your default editor. Add the following line to the user specification:
# Type: service
# Save the user specification and exit your default editor.
# By default, the service user is granted the same 12-hour login timeout as standard users. To prevent the service user's ticket from timing out, create a group with a long timeout on the master server. In this example, the Timeout: field is set to two billion seconds, approximately 63 years:

p4 group service_group
Users: service
Timeout: 2000000000
# For more details, seeTickets and timeouts for service users.
# Set the service user protections to super in your protections table. (See Permissions for service users.) It is good practice to set the security level of all your Perforce Servers to at least 1 (preferably to 3, so as to require a strong password for the service user, and ideally to 4, to ensure that only authenticated service users may attempt to perform replica or remote depot transactions.)

p4 configure set security=4
p4 passwd

# Set the Replica1 configurable for the serviceUser to service.
p4 configure set Replica1#serviceUser=service

# This step configures the replica server to authenticate itself to the master server as the service user; this is equivalent to starting p4d with the -u service option.
# If the user running the replica server does not have a home directory, or if the directory where the default .p4tickets file is typically stored is not writable by the replica's Perforce server process, set the replica P4TICKETS value to point to a writable ticket file in the replica's Perforce server root directory:
p4 configure set "Replica1#P4TICKETS=/p4/replica/.p4tickets"
