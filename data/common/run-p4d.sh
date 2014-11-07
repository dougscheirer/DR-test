#!/bin/bash
function die()
{
	echo $1 && exit 1
}

if [ "$1" == "" ] ; then
	die "need to run with a perforce directory root, e.g. /var/perforce/p4d"
fi

export P4PORT=1666
export P4LOG=p4d.log
export P4ROOT=$1
export P4JOURNAL=$1/journal

/opt/perforce/sbin/p4d -InMaster -v server=2 -d || die "failed to start p4d"

