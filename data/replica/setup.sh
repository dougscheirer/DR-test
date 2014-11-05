#!/bin/bash

function die()
{
        echo $1 && exit 1
}

echo "it works" || die "it does not work"

