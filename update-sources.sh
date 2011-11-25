#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

qt5hash=$(cat $d/qt5-pinned-hash)

echo "Updating qt..."
cd $qt5_dir
if [ `git rev-parse HEAD` != "$qt5hash" ]; then
    git fetch --recurse-submodules
    git checkout $qt5hash
    git submodule update --recursive
    echo "Qt sources updated. You need to rebuild Qt."
else
    echo "Qt sources are already up-to-date."
fi
cd ../..

echo "Updating webkit..."
cd $webkit_dir
git pull --rebase
cd ..

echo "Done"


