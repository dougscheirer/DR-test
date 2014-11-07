#!/bin/bash
function die()
{
	echo $1 && exit 1
}

if [ "$1" == "" ] ; then
	die "need to run with a root, e.g. /var/perforce/p4d"
fi

export P4ROOT=$1
export P4PORT=1666

p4d -p$P4PORT -r$P4ROOT -In Replica1 -d
