
sanity_check_symlinks() {
    echo -n "Checking $SYSROOT_DIR for absolute symlinks ..."
    local usrlib=$SYSROOT_DIR/usr/lib
    for link in `find $usrlib -maxdepth 1 -type l`; do
        target=`readlink $link`
        if [[ $target == /* ]]; then
            echo
            echo "Found absolute symlink in $usrlib. That won't work with --sysroot. Call resolve-absolute-links-in-scratchbox-sysroot.sh to fix this."
            return 1
        fi
    done
    echo " Done."
    return 0
}

setup_sysroot_from_scratchbox() {
    if [ -n "$SBOX_UNAME_MACHINE" ]; then
        echo "Cannot do sysroot builds from within Scratchbox."
        return 1
    fi
    local sbox_dir=/scratchbox/users/$USER/
    if [ ! -d $sbox_dir ]; then
        echo "Cannot locate scratchbox dir. Was looking for $sbox_dir"
        return 1
    fi
    local config=$sbox_dir/targets/links/scratchbox.config
    if [ ! -h $config ]; then
        echo "Cannot find scratchbox config symlink. Was looking for $config"
        return 1
    fi
    config=$sbox_dir/`readlink $config`
    local target_dir=`source $config && echo $SBOX_TARGET_DIR`
    target_dir=$sbox_dir$target_dir
    export SYSROOT_DIR=$target_dir
    return 0
}

if ! setup_sysroot_from_scratchbox; then
    return 1
fi

export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$SYSROOT_DIR/usr/lib/pkg-config
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT_DIR

setup_toolchain() {
    local script_file=`readlink -f $1`
    local script_dir=`dirname $script_file`
    local toolchainDir=$script_dir/arm-toolchain-bin
    if [ ! -d $toolchainDir ]; then
        echo "Could not locale toolchain in $toolchainDir. Run setup-arm-toolchain-bin.sh once to set up the toolchain symlinks."
        return 1
    fi
    export PATH=$toolchainDir:$PATH
    return 0
}

if ! setup_toolchain $0; then
    return 1
fi

if ! sanity_check_symlinks; then
    return 1
fi

true
