#!/bin/sh

d=`dirname $0`
. $d/common.sh

set -e

echo "Updating qt..."
cd $qt5_dir
git fetch --recurse-submodules
git checkout 6df6e99be09731991a1689cf1a71c601f4814865
git submodule update --recursive
cd ../..

echo "Updating webkit..."
cd $webkit_dir
git pull --rebase
cd ..

echo "Done"


