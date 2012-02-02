#!/bin/bash

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

arch=`uname -m | sed -e "s,i.*,i686-pc," -e "s,x86_64,x86_64-unknown,"`
toolChainPath=$sdkPath/Madde/toolchains/arm-2009q3-67-arm-none-linux-gnueabi-$arch-linux-gnu/arm-2009q3-67/bin

if [ ! -d "$toolChainPath" ]; then
    echo "Cannot locate Qt SDK. Tried looking in \"$sdkPath\". Please provide the path to your SDK"
    echo "as argument to this script."
    exit 1
fi

symlinkPath=$script_dir/arm-toolchain-bin
if [ -d $symlinkPath ]; then
    echo "Looks like the toolchain symlinks are already set up in $symlinkPath. Nothing to do then."
    exit 1
fi

mkdir -p $symlinkPath

for file in `cd $toolChainPath; ls arm-none-linux-gnueabi-*`; do
    ln -s $toolChainPath/$file $symlinkPath/`echo $file | sed -e "s,none-,,"`
done

echo "Okay, now is a good time to put $symlinkPath into your PATH."
