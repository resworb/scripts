#!/bin/sh

d=`dirname $0`
. $d/common.sh

set -e

echo "Installing deps..."

$sudo apt-get -y --force-yes build-dep qt4-x11

deps_install_host="\
libxcb1 \
libxcb1-dev \
libx11-xcb1 \
libx11-xcb-dev \
libxcb-keysyms1 \
libxcb-keysyms1-dev \
libxcb-image0 \
libxcb-image0-dev \
libxcb-shm0 \
libxcb-shm0-dev \
libxcb-icccm1 \
libxcb-icccm1-dev \
libxcb-sync0 \
libxcb-sync0-dev \
libxcb-xfixes0-dev \
"

deps_install_m=$deps_install_host;

deps_purge_host="\
libxcb-render-util0 \
libxcb-render-util0-dev
"

deps_purge_m="\
libxcb-render-util0 \
libxcb-render-util0-dev
"

deps_install_m_armel="\
libgles2 \
libgles2-sgx-img-dev \
opengles-sgx-img-common \
opengles-sgx-img-common-dev \
meego-gstreamer0.10-interfaces-dev \
libxcb1 \
libxcb1-dev \
libx11-xcb1 \
libx11-xcb-dev \
libxcb-keysyms1 \
libxcb-keysyms1-dev \
libxcb-image0 \
libxcb-image0-dev \
libxcb-shm0 \
libxcb-shm0-dev \
libxcb-icccm1 \
libxcb-icccm1-dev \
libxcb-sync0 \
libxcb-sync0-dev \
libxcb-xfixes0-dev
"

deps_install_m_i386="libgl-dev libgl1"

if [ $device_target == "host" ]; then
    #target contains deps for: qt, webkit, grob-m5, grob-m6
       deps_install=$deps_install_host
       deps_purge=$deps_purge_host
else
   if [ $meego_target == "m6" ]; then
    #target contains deps for: webkit, grob-m6
       deps_install=$deps_install_m
       deps_purge=$deps_purge_m
   else
    #target contains deps for: webkit, grob-m5
       deps_install=$deps_install_m
       deps_purge=$deps_purge_m
   fi
   if [ $device_target == "armel" ]; then
       deps="$deps $deps_install_m_armel"
   else
       deps="$deps $deps_install_m_i386"
   fi
fi

(dpkg --status $deps_install 2>&1 | grep not.installed ) && \
 ($sudo apt-get update && $sudo apt-get -y --force-yes install $deps_install)

$sudo apt-get -y --force-yes remove --purge $deps_purge

echo "Done"

