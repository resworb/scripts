#!/bin/bash

harmattan_target=harmattan_10.2011.34-1

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

if [ ! -d $sdkPath ]; then
    echo "Cannot locate Qt SDK. Tried looking in \"$sdkPath\". Please provide the path to your SDK"
    echo "as argument to this script."
    exit 1
fi

madAdmin=$sdkPath/Madde/bin/mad-admin

if [ ! -e "$madAdmin" ]; then
    echo "Cannot locate Madde inside the Qt SDK. Did you forget to install the Harmattan packages in the Qt SDK?"
    exit 1
fi

madAdmin="$madAdmin -t $harmattan_target"

set +e
$madAdmin query sysroot-dir >/dev/null
if [ $? != 0 ]; then
    echo "Cannot locate Harmattan sysroot. Tried locating it with mad-admin and $harmattan_target as target. Did you forget"
    echo "to install the Harmattan packages in the Qt SDK?"
    exit 1
fi
set -e

statusFile=`$madAdmin query sysroot-dir`/var/lib/dpkg/status

if [ ! -r $statusFile ]; then
    echo "Cannot read dpkg status file. Expected it at $statusFile."
    exit 1
fi

baseUrl="http://harmattan-dev.nokia.com/pool/harmattan-beta3/free"

cat $d/packages | while read package; do
    if [ -z "$package" -o "${package:0:1}" == "#" ]; then
        continue
    fi

    srcPackage=`echo $package | cut -d : -f 1`
    name=`echo $package | cut -d : -f 2`

    case $srcPackage in
        lib*)
            prefix=`echo $srcPackage | cut -c 1-4`
            ;;
        *)
            prefix=`echo $srcPackage | cut -c 1`
            ;;
    esac

    url=$baseUrl/$prefix/$srcPackage/$name".deb"
    localFile=/tmp/missing_package.deb
    wget -O $localFile $url
    $madAdmin xdpkg -i $localFile
    rm -f $localFile
done

