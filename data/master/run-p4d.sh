#!/bin/bash
logger $1

export P4PORT=1666
export P4LOG=p4d.log
export P4ROOT=$1
export P4JOURNAL=$1/journal
/opt/perforce/sbin/p4d -v server=2 -d

