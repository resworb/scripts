#!/bin/bash

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
    (cd qtbase && git fetch http://codereview.qt-project.org/p/qt/qtbase refs/changes/54/15954/1 && git cherry-pick FETCH_HEAD)
    (cd qtquick1 && git fetch http://codereview.qt-project.org/p/qt/qtquick1 refs/changes/81/15981/1 && git cherry-pick FETCH_HEAD)
    echo "Qt sources updated. You need to rebuild Qt."
else
    echo "Qt sources are already up-to-date."
fi

