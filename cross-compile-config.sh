
setup_sysroot_from_sdk() {
    local harmattan_target=harmattan_10.2011.34-1

    if [ -n "$SBOX_UNAME_MACHINE" ]; then
        echo "Cannot do sysroot builds from within Scratchbox."
        return 1
    fi
    if [ -n "$SYSROOT_DIR" ]; then
        echo "Using specified sysroot at $SYSROOT_DIR"
        return 0
    fi
    local sdkPath=$HOME/QtSDK
    if [ ! -d $sdkPath ]; then
        echo "Cannot locate Qt SDK. Tried looking in \"$sdkPath\"."
        exit 1
    fi
    local madAdmin="$sdkPath/Madde/bin/mad-admin"
    if [ ! -e "$madAdmin" ]; then
        echo "Cannot locate Madde inside the Qt SDK. Did you forget to install the Harmattan packages in the Qt SDK?"
        exit 1
    fi
    export SYSROOT_DIR=`$madAdmin -t $harmattan_target query sysroot-dir`
    echo "Using sysroot at $SYSROOT_DIR"
    return 0
}

setup_toolchain() {
    local script_file=`readlink -f $1`
    local script_dir=`dirname $script_file`
    local toolchainDir=$script_dir/arm-toolchain-bin
    if [ ! -d $toolchainDir ]; then
        echo "Could not locale toolchain in $toolchainDir. Run setup-arm-toolchain-bin.sh once to set up the toolchain symlinks."
        return 1
    fi
    export PATH=$toolchainDir:$PATH
    if [ -x setup-icecc-cross-env.sh ] ; then
        . setup-icecc-cross-env.sh
    fi
    return 0
}

if [ "$1" != "--parse-only" ]; then

    if ! setup_sysroot_from_sdk; then
        return 1
    fi

    export PKG_CONFIG_PATH=
    export PKG_CONFIG_LIBDIR=$SYSROOT_DIR/usr/lib/pkgconfig
    export PKG_CONFIG_SYSROOT_DIR=$SYSROOT_DIR


    if ! setup_toolchain $0; then
        return 1
    fi
fi

true
