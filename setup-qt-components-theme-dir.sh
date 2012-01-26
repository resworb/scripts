#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

if is_sbox; then
    echo "Running in Scratchbox, nothing to setup."
    exit 0
fi

prf_file="$qt5_dir/qtbase/mkspecs/features/meegotouch_defines.prf"

if [ -e "$prf_file" ]; then
    . $prf_file
    echo "Looks like themes are already setup, configured to $M_THEME_DIR"
    exit 0
fi

qtVersionFile=$HOME/.config/Nokia/qtversion.xml
if [ ! -e "$qtVersionFile" ]; then
    echo "Cannot locate Qt version file at $qtVersionFile - Did you forget to install the Qt SDK?"
    exit 1
fi

set +e
qmakePath=`cat $qtVersionFile | sed -n -e "s,.\+key=\"QMakePath\">\(.\+QtSDK/Simulator/Qt/gcc/bin/qmake\)</value>$,\\1,p"`
if [ $? != 0 -o -z "$qmakePath" ]; then
    echo "Cannot find Harmattan target in Qt SDK. Did you forget to install it?"
    exit 1
fi
set -e
themePath=`$qmakePath -query QT_INSTALL_DATA`/harmattanthemes

if [ -d $themePath -a -d $themePath/blanco ]; then
    echo "Found theme dir in $themePath"
else
    echo "Could not locate theme path. Was looking in $themePath"
    exit 1
fi

themePath=`cd $themePath && pwd`
echo M_THEME_DIR=$themePath > $prf_file
