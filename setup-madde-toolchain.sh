#!/bin/bash
script_root=$(dirname $0)
# -------------------------------------------------------------------

# FIXME: At some point we might have to support multiple targets
# At that point we'll have to deduct the content of the config file
# based on the chosen base target, rather than hard-coding it. This
# can be done using the targets 'information' file if needed.
harmattan_base_target="harmattan_10.2011.34-1_rt1.2"

custom_postfix="qt5"

repo_base_url="http://harmattan-dev.nokia.com/pool/harmattan/free"

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
    unset sourced
    trap cleanup 2

    cleanup() 
    {
        echo
        exit 1
    }

    while [ $# != 0 ]; do
    case "$1" in
        --force)
            force=1
            ;;
        --full)
            full=1
            ;;
        *)
            echo "Unknown flag '$1'"
            exit 1
            ;;
    esac
    shift
done
fi

in_array() {
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}

install_packages()
{
    package_list=($1)
    package_repo=$2
    distribution=$3

    arch="binary-armel"

    echo "Fetching packages from $package_repo ($distribution)..."

    install_next=0

    OLD_IFS=$IFS
    IFS=$'\n'
    for line in $(curl -s $package_repo/dists/$distribution/$arch/Packages); do
        if [[ $line =~ ^Package:.* ]]; then
            package=${line#Package: }
            in_array $package "${package_list[@]}" && {
                $mad_admin -t $custom_target_name xdpkg -p $package 2>/dev/null >/dev/null
                if [ $? != 0 -o -n "$force" ]; then
                    install_next=1
                fi
            }
        elif [[ $line =~ ^Filename:.* ]]; then
            if [ $install_next == 1 ]; then
                filename=${line#Filename: }
                url=$package_repo/$filename
                echo "Downloading $url..."
                local_file=/tmp/missing_package.deb
                wget -q -O $local_file $url
                if [ $? != 0 ]; then
                    echo "Failed to download $url!"
                    exit 1
                fi
                $mad_admin -t $custom_target_name xdpkg -i $local_file
                rm -f $local_file
            fi
            install_next=0
        fi
    done
    IFS=$OLD_IFS
}

possible_madde_paths=(
    "$HOME/QtSDK/Madde/bin"
    "$HOME/Applications/QtSDK/Madde/bin"
    "/Applications/QtSDK/Madde/bin"
    "$QTSDK/Madde/bin"
    "$(dirname $(command -v mad-admin || echo \"\"))"
)

for possible_path in "${possible_madde_paths[@]}"; do
    if [ -e "$possible_path/mad-admin" ]; then
        mad_admin="$possible_path/mad-admin"
        break
    fi
done

if [ -z "$mad_admin" ]; then
    cat <<EOF
Could not find MADDE. Please make sure the MADDE tools such as 'mad' and 'mad-admin' are in
your PATH. If you've installed the Qt SDK you'll find these tools in \$QTSDK/Madde/bin.
EOF
    test $sourced && return || exit 1
else
    test $sourced || echo "Using MADDE from $(dirname $mad_admin)"
fi

mad_install_dir=$($mad_admin query install-dir)

if [ ! -d "$($mad_admin -t $harmattan_base_target query target-dir 2>&1)" ]; then
    echo "Target '$harmattan_base_target' not found. Please install it first."
    echo "If you've installed the Qt SDK this target should come with the SDK."
    test $sourced && return || exit 1
fi

test $sourced || echo "Found base harmattan target '$harmattan_base_target'"

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

    envs=(PATH SYSROOT_DIR PKG_CONFIG_PATH PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_LIBDIR)
    echo "Environment set up to use $custom_target_name:\n"
    for variable in "${envs[@]}"; do
        echo "    $variable=$(eval echo \$$variable)"
    done
    echo
    return
fi

echo "Installing packages..."

# These pacakges are required for building Qt5

base_packages="""
    libfontconfig1-dev
    libfreetype6-dev
    libncurses5-dev
    libpng12-dev
    libreadline5-dev
    libtiff4-dev
    libtiffxx0c2
    libx11-xcb-dev
    libxcb-atom1
    libxcb-atom1-dev
    libxcb-aux0
    libxcb-damage0-dev
    libxcb-damage0
    libxcb-event1-dev
    libxcb-event1
    libxcb-icccm1-dev
    libxcb-icccm1
    libxcb-image0-dev
    libxcb-image0
    libxcb-keysyms1-dev
    libxcb-keysyms1
    libxcb-property1-dev
    libxcb-property1
    libxcb-render-util0
    libxcb-render-util0-dev
    libxcb-render0-dev
    libxcb-shape0-dev
    libxcb-shm0-dev
    libxcb-shm0
    libxcb-sync0-dev
    libxcb-sync0
    libxcb-xfixes0-dev
    libxcb-xfixes0
    libxcb-randr0-dev
    libxdmcp-dev
    libxdmcp6
    libxft-dev
    libxi-dev
    libxmu-dev
    libxmu-headers
    libxmu6
    libxrandr-dev
    libxslt1-dev
    meego-gstreamer0.10-interfaces-dev
"""

install_packages "$base_packages" "http://harmattan-dev.nokia.com" "harmattan/sdk/free"

target_dir=$($mad_target_admin query target-dir)
sysroot_dir=$($mad_target_admin query sysroot-dir)

prefix="/opt/qt5"

if [ -n "$full" ]; then
    # Install binary packages for Qt5, Components, and WebKit
    extra_pacakges="""
        qt5-base
        qt5-declarative
        qt5-jsbackend
        qt5-location
        qt5-jsondb
        qt5-q3d
        qt5-quick1
        qt5-script
        qt5-sensors
        qt5-xmlpatterns
        qt-components2
        webkit-snapshot
"""

    install_packages "$extra_pacakges" "http://qtlabs.org.br/~lmoura/qt5" "unstable/main"

    target_dir=$($mad_target_admin query target-dir)
    old_cwd=$(pwd)
    cd $target_dir/bin

    for binary in $(find $sysroot_dir$prefix/bin -maxdepth 1 -perm +111 -type f); do
        ln -sf $binary $(basename $binary)
    done
    cd $old_cwd

    mkspecs_dir="$sysroot_dir$prefix/mkspecs"

    cat >> $mkspecs_dir/qconfig.pri <<EOF

QMAKE_CFLAGS    *= --sysroot=\$\$[QT_SYSROOT]
QMAKE_CXXFLAGS  *= --sysroot=\$\$[QT_SYSROOT]
QMAKE_LFLAGS    *= --sysroot=\$\$[QT_SYSROOT]

EOF

    # Set a default mkspec
    ln -sf $mkspecs_dir/linux-arm-gnueabi-g++ $mkspecs_dir/default
fi

if [ $? != 0 ]; then
    exit 1
fi


cat <<EOF

Congratulations! You should now be able to build Qt5 against the following sysroot:

  $sysroot_dir

With the following toolchain in your path:

  $target_dir/bin

You may source this script to set environment variables accordingly.

EOF

if [ -n "$full" ]; then

    cat <<EOF
You've also installed pre-built binary packages of Qt5, QtComponents, and WebKit. If you
are cross-compiling on OS X you need to build the base tools for your host system:

    configure \$OPTIONS -prefix $prefix -hostprefix \$SYSROOT_DIR$prefix

And then:

    cd qtbase && make install_qmake && cd src/tools && make && make install

EOF
fi
