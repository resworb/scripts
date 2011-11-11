#!/bin/sh

d=`dirname $0`
. $d/common.sh

set -e

echo "Get the sources..."

cd $shared_dir

if [ -e ${qt5_dir} ]; then
    echo "$qt5_dir already exists, you should probably run update-sources.sh"
else
    git clone git://gitorious.org/qt/qt5.git qt5
    cd qt5
    git checkout 5981f1728697d2afae25a17f2094769c69142787
    ./init-repository --module-subset=qtbase,qtxmlpatterns,qtscript,qtdeclarative
fi

cd $shared_dir

if [ -e ${webkit_dir} ]; then
    echo "$webkit_dir already exists, you should probably run update-sources.sh"
else
    git clone git@gitorious.org:webkit/webkit.git
fi

echo "Done"


