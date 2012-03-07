#!/bin/bash
script_root=$(dirname $0)
. $script_root/common.sh

keyfile="$HOME/.ssh/id_rsa.pub"
[ -f $keyfile ] || die "You don't have a public key. Use ssh-keygen to create one"
key=$(cat $keyfile)

if ! grep -q "Host device" ~/.ssh/config; then
	echo "Adding device to SSH config..."
	printf "\nHost device\n    Hostname 192.168.2.15\n    User developer\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> ~/.ssh/config
fi

if ! is_macos; then
	echo "Bringing up device..."
	while [ -z "$(ifconfig usb0 2>/dev/null | grep UP 2>/dev/null)" ]; do
		sudo ifdown usb0 2>/dev/null; sleep 1; sudo ifup usb0 2>/dev/null; sleep 1;
		if [ -z "$(ifconfig usb0 2>/dev/null | grep UP 2>/dev/null)" ]; then
			echo "Unplug device. Wait. Disconnect internet. Plug it again. Press [enter]"
			read dummy
		fi
	done
fi

device_script="/tmp/setup-device.sh"
mount_script="mount-host.sh"

ssh -q developer@device <<EOF
mkdir -p \$HOME/.ssh
grep '$key' \$HOME/.ssh/authorized_keys >/dev/null 2>&1 || echo '$key' >> \$HOME/.ssh/authorized_keys
chmod -R 700 \$HOME/.ssh
EOF

cat > $device_script << EOF
#!/bin/sh
script=\$(readlink -f \$0)

if [ "\$(whoami)" != "root" ]; then
    echo "Running \$script as root..."
    echo rootme | devel-su root -c "\$script"
    exit
fi

# Tweak some settings for easier development
gconftool --set /system/osso/dsm/display/display_brightness --type=int 5
#gconftool --set /system/osso/dsm/display/inhibit_blank_mode --type=int 1

echo "Verifying Internet connectivity..."
if ! nslookup google.com 8.8.8.8 > /dev/null 2>&1; then
	echo "Please ensure that the device is connected to the Internet."
	dbus-send --system --type=method_call --dest=com.nokia.icd_ui /com/nokia/icd_ui com.nokia.icd_ui.show_conn_dlg boolean:false
	while [ \$(nslookup google.com 8.8.8.8 > /dev/null 2>&1; echo \$?) != 0 ]; do
		echo "Waiting..."
		sleep 1
	done
fi

echo "Installing packages..."

cat > /etc/apt/sources.list.d/extras.list <<EOL
deb-src http://harmattan-dev.nokia.com/ harmattan/sdk free
deb http://harmattan-dev.nokia.com/ harmattan/sdk free non-free
deb http://repo.pub.meego.com/home:/rzr:/harmattan/MeeGo_1.2_Harmattan_Maemo.org_MeeGo_1.2_Harmattan_standard/ ./
EOL

apt-get update

apt-get -qq --force-yes install wget libxcb-image0 libxcb-keysyms1 libxcb-icccm1 libxcb-aux0 libxcb-event1 libxcb-property1 libxcb-atom1 libxcb-sync0 libxcb-xfixes0 libxcb-render-util0

# Verify that we're allowed to mount (open-mode or device has R&D certificates)
mkdir -p /tmp/mnt-src /tmp/mnt-dst
mount -o bind /tmp/mnt-src /tmp/mnt-dst > /dev/null 2>&1
allowed_to_mount=\$(test \$? == 0 && echo "yes")

if test \$allowed_to_mount && cat /var/cache/sysinfod/values | grep /device/sw-release-ver | grep -q "20.2011.40-4"; then
	apt-get -qq --force-yes install sshfs

	echo "Setting up SSHFS..."

	# FIXME: Check if we have open mode or aegis-su

	mkdir -p ~/.ssh
	if ! grep -q "Host host" ~/.ssh/config > /dev/null 2>&1; then
		echo "Adding host to SSH config..."
		printf "\nHost host\n    Hostname 192.168.2.14\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n    ServerAliveInterval 120" >> ~/.ssh/config
	fi

	profile="/home/developer/.profile"
	if ! grep -q "$mount_script" \$profile > /dev/null 2>&1; then
		 devel-su developer -c "echo \"/home/developer/bin/$mount_script\" >> \$profile"
		 devel-su developer -c "chown user:developer \$profile"
	fi

	# FIXME: For some reason this does not work (does not mount), without -o reconnect
	# and appears to mount but fails with "Input/output error" with -o reconnect.
	# /home/developer/bin/$mount_script
else
	echo "Firmware PR1.1 (20.2011.40-4) on an openmode patched kernel required for SSHFS. Skipping."
fi

EOF

chmod 755 $device_script
scp -q $device_script device:$device_script

cat > /tmp/$mount_script << EOF
#!/bin/sh
script=\$(readlink -f \$0)

if [ -z \$TERM ]; then exit; fi

if [ "\$(whoami)" != "root" ]; then
    echo rootme | devel-su root -c "\$script"
    exit
fi

if ! mount | grep -q /mnt/host ; then
	echo "Mounting host via SSHFS, please enter password for $USER"
	mkdir -p /mnt/host
	sshfs $USER@host:/ /mnt/host -o allow_other -o cache=no -o uid=29999 -o gid=30027 -o reconnect
	if [ $? -eq 0 ]; then
		mkdir -p $(dirname $HOME) &&
		ln -f -s /mnt/host$HOME $HOME &&
		echo "Your host is now available at /mnt/host and $HOME"
	fi
fi
EOF

chmod 755 /tmp/$mount_script
scp -q /tmp/$mount_script device:~/bin/$mount_script

ssh -q -t -t developer@device "$device_script"

echo "Success! The device has now been set up for Qt5 development"
