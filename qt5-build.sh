#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

x11r6_defined=$(echo $PATH | grep "X11R6" || true)

if [ -n "$x11r6_defined" ]; then
    die "The path to /usr/X11R6/bin needs to be removed from your PATH"
fi

if [ $device_target == "armel" ]; then
    extra_configure_flags="-platform unsupported/linux-host-g++ -xplatform linux-g++-maemo -force-pkg-config"
fi

cd $qt5_dir

if [ -n "${clean}" ]; then
    echo "Cleaning Qt5 directory..."
    git submodule foreach git clean -fdx
    git clean -fdx
fi

echo "Building Qt5..."

./configure -fast -nomake demos -nomake examples -nomake tests -nokia-developer $extra_configure_flags
make $makeargs

cd $shared_dir

echo
echo "Build completed, run the following to use your new Qt build:"
echo "export PATH=$qt5_dir/qtbase/bin:\$PATH"


