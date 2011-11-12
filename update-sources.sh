#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

qt5hash=$(cat $d/qt5-pinned-hash)

echo "Updating qt..."
cd $qt5_dir
git fetch --recurse-submodules
git checkout $qt5hash
git submodule update --recursive
cd ../..

echo "Updating webkit..."
cd $webkit_dir
git pull --rebase
cd ..

echo "Done"


