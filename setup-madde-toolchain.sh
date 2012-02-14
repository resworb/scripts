#!/bin/bash
script_root=$(dirname $0)
# -------------------------------------------------------------------

# FIXME: At some point we might have to support multiple targets
# At that point we'll have to deduct the content of the config file
# based on the chosen base target, rather than hard-coding it. This
# can be done using the targets 'information' file if needed.
harmattan_base_target="harmattan_10.2011.34-1"

custom_postfix="qt5"

repo_base_url="http://harmattan-dev.nokia.com/pool/harmattan-beta3/free"

# -------------------------------------------------------------------

create_custom_target()
{
    cat > $mad_install_dir/cache/madde.conf.d/harmattan_for_qt5.conf <<EOF
require harmattan-sysroot

target $custom_target_name
    sysroot harmattan_sysroot_10.2011.34-1_slim
    toolchain arm-2009q3-67-arm-none-linux-gnueabi
end
EOF

    echo "Creating custom target for Qt5 development..."
    $mad_admin create $custom_target_name
    if [ $? != 0 ]; then
        exit 1
    fi

    target_dir=$($mad_target_admin query target-dir)
    toolchain=$(cat $target_dir/information | grep toolchain | awk '{ print $2 }')

    # FIXME: We hard-code the toolchain subfolder for now
    toolchain_bin="$mad_install_dir/toolchains/$toolchain/arm-2009q3-67/bin"

    # For some handy defines
    source $target_dir/config.sh

    old_cwd=$(pwd)
    cd $target_dir/bin

    echo "Setting up symlinks for cross-compile-binaries..."

    # Make symlinks in the toolchain to match what the Qt mkspecs expect
    # We can't symlink to the binaries that are already there, as some of
    # them are wrappers around gcc for translating sysroots automatically.
    # We also have to remove the existing binaries so that they won't
    # conflict with the system when we put the toolchain in the path.
    for binary in $(find . -maxdepth 1 -perm +111 -type f); do
        binary=$(basename $binary)
        rm $binary
        ln -s $toolchain_bin/$DEB_BUILD_GNU_CPU-none-$DEB_BUILD_GNU_SYSTEM-$binary $DEB_BUILD_GNU_TYPE-$binary
    done
    cd $old_cwd
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    sourced=1
else
    trap cleanup 2

    cleanup() 
    {
        echo
        exit 1
    }
fi

# Assume it's in the default QtSDK path
mad_admin=$HOME/QtSDK/Madde/bin/mad-admin
if [ ! -e $mad_admin ]; then
    # Try to look for it in the path. This might pick up a system-MADDE
    mad_admin=$(command -v mad-admin)
    if [ $? != 0 ]; then
        cat <<EOF
Could not find MADDE. Please make sure the MADDE tools such as 'mad' and 'mad-admin' are in
your PATH. If you've installed the Qt SDK you'll find these tools in \$QTSDK/Madde/bin.
EOF
        test $sourced && return || exit 1
    fi
fi

mad_install_dir=$($mad_admin query install-dir)

if [ ! -d "$($mad_admin -t $harmattan_base_target query target-dir 2>&1)" ]; then
    echo "Target '$harmattan_base_target' not found. Please install it first."
    echo "If you've installed the Qt SDK this target should come with the SDK."
    test $sourced && return || exit 1
fi

echo "Found base harmattan target '$harmattan_base_target'"

custom_target_name="${harmattan_base_target}_${custom_postfix}"
mad_target_admin="$mad_admin -t $custom_target_name"

if [ ! -d "$($mad_admin -t $custom_target_name query target-dir 2>&1)" ]; then
    if [ $sourced ]; then
        echo "Missing custom target. Please run this script normally before sourcing"
        return
    else
        create_custom_target
    fi
fi

if [ $sourced ]; then
    sysroot_dir=$($mad_admin -t $custom_target_name query sysroot-dir)
    export PATH=$($mad_admin -t $custom_target_name query target-dir)/bin:$PATH
    export SYSROOT_DIR=$sysroot_dir

    export PKG_CONFIG_PATH=
    export PKG_CONFIG_SYSROOT_DIR=$SYSROOT_DIR
    export PKG_CONFIG_LIBDIR=$SYSROOT_DIR/usr/lib/pkgconfig

    echo "Environment set up to use $custom_target_name"
    return
fi

echo "Installing packages..."

cat $script_root/packages | while read package_spec; do
    if [ -z "$package_spec" -o "${package_spec:0:1}" == "#" ]; then
        continue
    fi

    package_base=$(echo $package_spec | cut -d : -f 1)
    package_filename="$(echo $package_spec | cut -d : -f 2).deb"
    package_name=$(echo $package_filename | cut -d _ -f 1)
    $mad_target_admin xdpkg -p $package_name 2>/dev/null >/dev/null
    if [ $? == 0 ]; then
        continue
    fi

    case $package_base in
        lib*)
            prefix=$(echo $package_base | cut -c 1-4)
            ;;
        *)
            prefix=$(echo $package_base | cut -c 1)
            ;;
    esac

    url="$repo_base_url/$prefix/$package_base/$package_filename"
    local_file=/tmp/missing_package.deb
    wget -q -O $local_file $url
    if [ $? != 0 ]; then
        echo "Failed to download $url!"
        exit 1
    fi
    $mad_target_admin xdpkg -i $local_file
    rm -f $local_file
done

# Check the while loops exit code
if [ $? != 0 ]; then
    exit 1
fi

target_dir=$($mad_target_admin query target-dir)
sysroot_dir=$($mad_target_admin query sysroot-dir)

cat <<EOF

Congratulations! You should now be able to build Qt5 against the following sysroot:

  $sysroot_dir

With the following toolchain in your path:

  $target_dir/bin

You may source this script to set environment variables accordingly.

EOF

