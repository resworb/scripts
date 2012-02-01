#!/bin/bash

set -e

d=`dirname $0`
. $d/common.sh

qtcomponentshash=$(cat $d/qt-components-pinned-hash)

echo "Updating qt-components..."
cd $qtcomponents_dir
if [ `git rev-parse HEAD` != "$qtcomponentshash" ]; then
    git fetch
    git checkout $qtcomponentshash
    echo "Qt-Components sources updated. You need to rebuild Qt Components."
else
    echo "Qt-Components sources are already up-to-date."
fi

