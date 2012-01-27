#!/bin/sh

set -e

sdkPath=$1
if [ -n "$sdkPath" ]; then
    shift
else
    sdkPath=$HOME/QtSDK
fi

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

if [ ! -d $sdkPath ]; then
    echo "Cannot locate Qt SDK. Tried looking in \"$sdkPath\". Please provide the path to your SDK"
    echo "as argument to this script."
    exit 1
fi

themePath=$sdkPath/Simulator/Qt/gcc/harmattanthemes

if [ -d $themePath -a -d $themePath/blanco ]; then
    echo "Found theme dir in $themePath"
else
    echo "Cannot locate Harmattan theme in your Qt SDK installation. Did you forget to install"
    echo "the Qt Quick Components for Harmattan for the Qt Simulator?"
    echo
    echo "I tried looking in $themePath"
    exit 1
fi

echo M_THEME_DIR=$themePath > $prf_file
echo "Registered theme dir in $prf_file."
