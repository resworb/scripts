#!/bin/bash

harmattan_target=harmattan_10.2011.34-1

packages="\
fontconfig:libfontconfig1-dev_2.8.0-3osso8+0m6_all \
freetype:libfreetype6-dev_2.4.3-1osso6+0m6_armel \
ncurses:libncurses5-dev_5.7+20081213-6-maemo1+0m6_armel \
libpng:libpng12-dev_1.2.42-1meego1+0m6_armel \
readline5:libreadline5-dev_5.2-2maemo4+0m6_armel \
tiff:libtiff4-dev_3.9.4-1+maemo6+0m6_armel \
tiff:libtiffxx0c2_3.9.4-1+maemo6+0m6_armel \
libx11:libx11-xcb-dev_1.4.3-0-meego1241+0m6_armel \
xcb-util:libxcb-atom1-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-aux0_0.3.6-2+0m6_armel \
libxcb:libxcb-damage0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-damage0_1.7-1-meego1082+0m6_armel \
xcb-util:libxcb-event1-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-event1_0.3.6-2+0m6_armel \
xcb-util:libxcb-icccm1-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-icccm1_0.3.6-2+0m6_armel \
xcb-util:libxcb-image0-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-image0_0.3.6-2+0m6_armel \
xcb-util:libxcb-keysyms1-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-keysyms1_0.3.6-2+0m6_armel \
xcb-util:libxcb-property1-dev_0.3.6-2+0m6_armel \
xcb-util:libxcb-property1_0.3.6-2+0m6_armel \
libxcb:libxcb-render0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-shape0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-shm0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-shm0_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-sync0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-sync0_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-xfixes0-dev_1.7-1-meego1082+0m6_armel \
libxcb:libxcb-xfixes0_1.7-1-meego1082+0m6_armel \
libxdmcp:libxdmcp-dev_1.0.3-2-meego392+0m6_armel \
libxdmcp:libxdmcp6_1.0.3-2-meego392+0m6_armel \
xft:libxft-dev_2.1.14-2-meego393+0m6_armel \
libxi:libxi-dev_1.3-4-meego392+0m6_armel \
libxmu:libxmu-dev_1.0.5-1+dbg+0m6_armel \
libxmu:libxmu-headers_1.0.5-1+dbg+0m6_all \
libxmu:libxmu6_1.0.5-1+dbg+0m6_armel \
libxrandr:libxrandr-dev_1.3.0-3-meego392+0m6_armel \
libxslt:libxslt1-dev_1.1.19-1osso4+0m6_armel \
meego-gst-interfaces:meego-gstreamer0.10-interfaces-dev_0.10.1-0meego2+0m6_armel \
xorg:x11-common_7.3+10.0maemo2+0security1+0m6_all
"

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

for package in $packages; do
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

