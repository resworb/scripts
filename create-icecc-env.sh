#!/bin/sh

icecc_environment="host"

while [ $# != 0 ] ; do
    case "$1" in
        --environment)
            if [ $# -gt 1 ] ; then
                icecc_environment=$2
                shift
            else
                echo "Please pass --environment [host | scratchbox]"
                exit 1
            fi
            ;;
    esac
    shift
done

echo
echo "Using environment: $icecc_environment"
echo "==============================="
echo

if [ "x$icecc_environment" = "xhost" ] ; then
    icecc_home="$HOME/icecc"
    symlink=$icecc_home/icecc-build

    if [ ! -d $icecc_home ] ; then
        if ! mkdir -p $icecc_home ; then
            echo "Eek! Unable to create $icecc_home"
            exit 1
        fi
    fi

    file=$(icecc --build-native 2>&1 | grep "creating" | sed -n -e 's/creating \(.*\)/\1/p')
    mv $file $icecc_home/

    if [ -h $symlink ] ; then
        rm $symlink
    fi

    ln -s $file $symlink

    echo "Please put the following in your ~/.bashrc:"
    echo "-------------------------------------------"
    echo
    echo "icecc_tarball=\$(readlink -f $symlink)"
    echo "parallel_builds=\"40\""
    echo
    echo "if [ -f \$icecc_tarball ] ; then"
    echo "    export ICECC_VERSION=\"\$icecc_tarball\""
    echo "    export PATH=\"/usr/lib/icecc/bin:\$PATH\""
    echo "    export MAKEFLAGS=\"\$MAKEFLAGS -j\$parallel_builds\""
    echo "    export DEB_BUILD_OPTIONS=\"\$DEB_BUILD_OPTIONS,parallel=\$parallel_builds\""
    echo "fi"
    echo
    echo "-------------------------------------------"

elif [ "x$icecc_environment" = "xscratchbox" ] ; then
    if [ -L /targets/links/scratchbox.config ] ; then
        echo "Error: This script should be run *outside* scratchbox"
        exit 1
    fi

    tmpenv="$(mktemp -d icecc-sb-env-XXXXXX)"
    result="$(mktemp icecc-sb-env-XXXXXX).tar.gz"
    sbdir="/scratchbox"
    compiler=$(sb-conf show --compiler)
    toolchain_path="$sbdir/compilers/$compiler/bin"
    gcc_libexec_path="$sbdir/compilers/$compiler/libexec/gcc/$($toolchain_path/*-gcc -dumpmachine)/$($toolchain_path/*-gcc -dumpversion)/"
    icecchome="$sbdir/users/$USER/home/$USER/icecc"

    # Toolchain.
    mkdir -p $tmpenv/usr/bin

    for b in gcc g++ as ; do
        cp $toolchain_path/arm-none-linux-gnueabi-$b $tmpenv/usr/bin/$b
    done

    for b in cc1 cc1plus ; do
        cp $gcc_libexec_path/$b $tmpenv/usr/bin/$b
    done

    # System libraries for the cross-toolchain.
    mkdir -p $tmpenv/lib32

    for l in ld-linux.so.2 libm.so.6 libc.so.6 ; do
        cp /lib32/$l $tmpenv/lib32/$l
    done

    mkdir $tmpenv/lib

    ln -s ../lib32/ld-linux.so.2 $tmpenv/lib/ld-linux.so.2

    # ld.so.conf
    mkdir -p $tmpenv/etc
    echo "/lib\n/lib32" > $tmpenv/etc/ld.so.conf
    ldconfig -r $tmpenv/

    cd $tmpenv
    tar -czf $HOME/$result $(find . -type f -or -type l | sed -e 's/.\///')

    if [ ! -d $icecchome ] ; then
        mkdir -p $icecchome
    fi

    md5=$(md5sum $HOME/$result | cut -d' ' -f1)
    mv $HOME/$result $icecchome/$md5.tar.gz

    if [ -h $icecchome/icecc-build ] ; then
        rm $icecchome/icecc-build
    fi

    ln -s $icecchome/$md5.tar.gz $icecchome/icecc-build
    rm -rf $tmpenv

    # Check if IceCC is installed in sbox.
    if [ ! -f $sbdir/tools/bin/icecc ] || [ ! -f $sbdir/tools/bin/icecc++ ] ; then
        workdir="$(mktemp -d $icecchome/build-XXXXXX)"
        echo $workdir
        wget http://ftp.suse.com/pub/projects/icecream/icecc-0.9.7.tar.bz2 -O $workdir/icecc.tar.bz2
        tar xvjpf $workdir/icecc.tar.bz2 -C $workdir/
        echo "cd /home/$USER/icecc/$(basename $workdir)/icecc-* && ./configure CC=host-gcc CXX=host-g++ && make -j2" | $sbdir/login -s
        echo "Done building... Need to install the binaries..."
        sudo cp $workdir/icecc-*/client/icecc $sbdir/tools/bin/icecc
        sudo ln -s icecc $sbdir/tools/bin/icecc++
        rm -rf $workdir
    fi

    # Create $HOME/icecc/bin/.
    if [ ! -d $icecchome/bin ] ; then
        mkdir $icecchome/bin
    fi

    [ -h $icecchome/bin/cc ] || ln -s $sbdir/tools/bin/icecc $icecchome/bin/cc
    [ -h $icecchome/bin/gcc ] || ln -s $sbdir/tools/bin/icecc $icecchome/bin/gcc
    [ -h $icecchome/bin/g++ ] || ln -s $sbdir/tools/bin/icecc++ $icecchome/bin/g++

    echo "Please put the following in your scratchbox ~/.bashrc:"
    echo "-------------------------------------------"
    echo
    echo "icecc_tarball=\$(readlink -f \$HOME/icecc/icecc-build)"
    echo "parallel_builds=\"40\""
    echo
    echo "if [ -f \$icecc_tarball ] ; then"
    echo "    export ICECC_VERSION=\"i386:\$icecc_tarball,x86_64:\$icecc_tarball\""
    echo "    export PATH=\"/home/$USER/icecc/bin:\$PATH\""
    echo "    export MAKEFLAGS=\"\$MAKEFLAGS -j\$parallel_builds\""
    echo "    export DEB_BUILD_OPTIONS=\"\$DEB_BUILD_OPTIONS,parallel=\$parallel_builds\""
    echo "fi"
    echo
    echo "-------------------------------------------"

else
    echo "Uknown environment type \"$icecc_environment\""
    exit 1
fi
