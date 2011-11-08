#!/bin/sh

set -e

d=`dirname $0`
. $d/common.sh

#script_file=`readlink -f $0`
#script_dir=`dirname $script_file`

. $script_dir/qt5-build.sh

export PATH=$qt5_dir/qtbase/bin:$PATH

. $script_dir/webkit-build.sh

echo "Done"


