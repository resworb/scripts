#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

x11r6_defined=$(echo $PATH | grep "X11R6" || true)

if [ -n "$x11r6_defined" ]; then
    die "The path to /usr/X11R6/bin needs to be removed from your PATH"
fi

cd $qtcomponents_dir

if [ -n "${clean}" ]; then
    echo "Cleaning Qt-Components directory..."
    git clean -fdx
fi

echo "Building Qt-Components..."

./configure -meego
make $makeargs
make install

cd $shared_dir

echo
echo "Build completed. Qt Components have been installed into the Qt QML imports directory,"
echo "they can be used right away."


