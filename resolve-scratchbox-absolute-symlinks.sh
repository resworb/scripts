#!/bin/bash

sysroot=$1
if [ -z "$sysroot" ]; then
    echo "usage: $0 /path/to/sysroot"
    exit 1
fi

usrlib=$sysroot/usr/lib

if [ ! -d $usrlib ]; then
    echo "Cannot find /usr/lib in sysroot $sysroot. Did you specify the correct sysroot path?"
    exit 1
fi

echo "Looking for absolute symlinks..."
for link in `find $usrlib -maxdepth 1 -type l`; do
    target=`readlink $link`
    if [[ $target == /* ]]; then
        target=${sysroot}${target}
        common=$usrlib
        back=
        while [ "${target#$common}" = "${target}" ]; do
            common=$(dirname $common)
            back="../$back"
        done
        target=${back}${target#$common/}
        if [ -e $usrlib/$target ]; then
            echo "Fixing $link to be a relative link to $target"
            ln -sf $target $link
        fi
    fi
done
