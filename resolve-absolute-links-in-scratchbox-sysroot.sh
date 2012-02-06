#!/bin/bash

d=`dirname $0`
. $d/common.sh

. $script_dir/cross-compile-config.sh --parse-only
setup_sysroot_from_scratchbox

usrlib=$SYSROOT_DIR/usr/lib

if [ ! -d $usrlib ]; then
    echo "Cannot find /usr/lib in sysroot $SYSROOT_DIR. Did you specify the correct sysroot path?"
    exit 1
fi

echo "Looking for absolute symlinks in $usrlib..."
for link in `find $usrlib -maxdepth 1 -type l`; do
    target=`readlink $link`
    if [[ $target == /* ]]; then
        target=${SYSROOT_DIR}${target}
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
