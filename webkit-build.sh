#!/bin/sh

d=`dirname $0`
. $d/common.sh

set -e

cd $shared_dir

qt5_defined=$(echo $PATH | grep "qtbase" || true)

if [ -z "$qt5_defined" ]; then
    die "The path to qt5 needs to be defined before building WebKit"
fi

echo "Building WebKit..."

mkdir -p $webkit-builddir-$build_suffix
export WEBKITOUTPUTDIR=$PWD/$webkit-builddir-$build_suffix

$webkit_dir/Tools/Scripts/build-webkit --qt $webkit_buildmode \
    --makearg="CONFIG+=use_qt_mobile_theme ${makeargs}" \
    --no-3d-canvas \
    $qmake_valgrind \
    ${QMAKEARGS} 


