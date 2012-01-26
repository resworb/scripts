#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

$d/update-qt-sources.sh
$d/update-qt-components-sources.sh

echo "Updating webkit..."
cd $webkit_dir
git pull --rebase
cd ..

echo "Done"


