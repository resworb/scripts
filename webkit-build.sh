#!/bin/bash

d=`dirname $0`
. $d/common.sh

set -e

x11r6_defined=$(echo $PATH | grep "X11R6" || true)

if [ -n "$x11r6_defined" ]; then
    die "The path to /usr/X11R6/bin needs to be removed from your PATH"
fi

cd $shared_dir

qt5_defined=$(echo $PATH | grep "qtbase" || true)

if [ -z "$qt5_defined" ]; then
    die "The path to qt5 needs to be defined before building WebKit"
fi

echo "Building WebKit..."

mkdir -p $webkit-builddir-$build_suffix
export WEBKITOUTPUTDIR=$PWD/$webkit-builddir-$build_suffix

$webkit_dir/Tools/Scripts/build-webkit --qt $webkit_buildmode \
    --makeargs="${makeargs}" \
    --no-webgl \
    $qmake_valgrind \
    ${QMAKEARGS} 


