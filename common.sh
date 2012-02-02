# common script functionality
# variables exported
#  script_dir = script directory, absolute path

#  build_suffix= suffix of builddir: [webkit1|]-[armel|i386|host]-[m6]

set -e

die() {
    echo "$0: error: $1"
    exit 1
}

is_sbox() {
    if [ -z "$SBOX_UNAME_MACHINE" ]; then
        return 1
    fi
    return 0
}

sanity_check_symlinks() {
    local usrlib=$SYSROOT_DIR/usr/lib
    for link in `find $usrlib -maxdepth 1 -type l`; do
        target=`readlink $link`
        if [[ $target == /* ]]; then
            die "Found absolute symlink in $usrlib. That won't work with --sysroot. Call resolve-absolute-links-in-scratchbox-sysroot.sh to fix this."
        fi
    done
}

sanity_check_cross_compiler_symlinks() {
    set +e
    which arm-linux-gnueabi-g++ > /dev/null
    if [ $? != 0 ]; then
        die "Need arm-linux-gnueabi-g++ in PATH."
    fi
    set -e
}

setup_sysroot_from_scratchbox() {
    if is_sbox; then
        die "Cannot do sysroot builds from within Scratchbox."
    fi
    local sbox_dir=/scratchbox/users/$USER/
    if [ ! -d $sbox_dir ]; then
        die "Cannot locate scratchbox dir. Was looking for $sbox_dir"
    fi
    local config=$sbox_dir/targets/links/scratchbox.config
    if [ ! -h $config ]; then
        die "Cannot find scratchbox config symlink. Was looking for $config"
    fi
    config=$sbox_dir/`readlink $config`
    local target_dir=`source $config && echo $SBOX_TARGET_DIR`
    target_dir=$sbox_dir$target_dir
    export SYSROOT_DIR=$target_dir
}

setup_sbox_cross_compilation() {
    device_target=xarmel
    setup_sysroot_from_scratchbox

    export PKG_CONFIG_DIR=
    export PKG_CONFIG_LIBDIR=$SYSROOT_DIR/usr/lib/pkg-config
    export PKG_CONFIG_SYSROOT_DIR=$SYSROOT_DIR

    local toolchainDir=$script_dir/arm-toolchain-bin
    if [ ! -d $toolchainDir ]; then
        die "Could not locale toolchain in $toolchainDir. Run setup-arm-toolchain-bin.sh once to set up the toolchain symlinks."
    fi
    export PATH=$toolchainDir:$PATH

    sanity_check_symlinks
    sanity_check_cross_compiler_symlinks
}

script_file=`readlink -f $0`
script_dir=`dirname $script_file`

shared_dir=$script_dir/..
qt5_dir=$shared_dir/qt5
qtcomponents_dir=$shared_dir/qt-components
webkit_dir=$shared_dir/webkit

#default to host m6 build
device_target=${device_target:-"host"}
meego_target="m6"

d=`dirname $0`

if is_sbox; then
    sudo="fakeroot"
    device_target="$SBOX_DPKG_INST_ARCH"
else
    sudo="sudo"
fi


# export DEB_BUILD_OPTIONS=parallel=30 if you want 30 jobs
parallel_jobs=$(echo $DEB_BUILD_OPTIONS | sed -e 's/.*parallel=\([0-9]\+\).*/\1/')
if [ -n "$parallel_jobs" ]; then
    if [ "$parallel_jobs" = "$DEB_BUILD_OPTIONS" ]; then
	parallel_jobs=""
    fi
fi

if [ -z "$parallel_jobs" ]; then
    if [ -f /proc/cpuinfo ]; then
        parallel_jobs=$(expr $(grep 'processor' /proc/cpuinfo | wc -l) \* 2 + 1)
    fi
fi

if [ -z "$parallel_jobs" ]; then
    # most people have dual-cores..
    parallel_jobs=3
fi

makeargs=${makeargs:-"-j${parallel_jobs}"}
browser_buildmode=debug
webkit_buildmode=--release
webkit_buildmodedir=Release
webkit="qtwebkit-webkit2-dev"
release=
valgrind=
clean=
while [ $# -gt 0 ]; do
    case $1 in
        --release)
            release=1
            browser_buildmode=release
            shift
            ;;
        --webkit_release)
            webkit_buildmode=--release
            webkit_buildmodedir=Release
            shift
            ;;
        --m6)
            meego_target="m6"
            shift
            ;;
        --scratchbox-cross-compile)
            setup_sbox_cross_compilation
            shift
            ;;

        --webkit_debug)
            webkit_buildmode=--debug
	    webkit_buildmodedir=Debug
            shift
            ;;
        --valgrind)
            valgrind=1
            shift
            ;;
        --clean)
            clean=1
            shift
            ;;
        *)
            die "unknown flag $1"
            break
            ;;
    esac
done

is_release() {
    if [ -z "$release" ]; then
        return 1
    fi
    return
}

qmake_buildmode="CONFIG+=debug CONFIG-=release"
if is_release; then
    qmake_buildmode="CONFIG+=release CONFIG-=debug"
fi

build_suffix=$device_target-$meego_target

qmake_valgrind=""
valgrind_target=""
if [ -n "$valgrind" ]; then
    qmake_valgrind="--qmakearg=CONFIG+=valgrind"
    valgrind_target="-valgrind"
fi

build_suffix=$device_target-$meego_target$valgrind_target


