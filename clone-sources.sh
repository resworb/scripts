#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

qt5hash=$(cat $d/qt5-pinned-hash)

echo "Get the sources..."

cd $shared_dir

if [ -e ${qt5_dir} ]; then
    echo "$qt5_dir already exists, you should probably run update-sources.sh"
else
    git clone git@gitorious.org:qt/qt5.git qt5
    cd qt5
    git checkout $qt5hash
    ./init-repository --ssh --module-subset=qtbase,qtxmlpatterns,qtscript,qtdeclarative,qtsensors,qtlocation,qtquick3d
fi

cd $shared_dir

if [ -e ${webkit_dir} ]; then
    echo "$webkit_dir already exists, you should probably run update-sources.sh"
else
    git clone git@gitorious.org:webkit/webkit.git
fi

echo "Done"


