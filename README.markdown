Resworb Scripts
===============

Scratchbox Instructions
-----------------------

1. Follow instructions here to get Scratchbox for Harmattan installed:

http://www.developer.nokia.com/Community/Wiki/Harmattan:Platform_Guide/Getting_started_with_Harmattan_Platform_SDK/Installing_Harmattan_Platform_SDK

Quick steps:

    $ wget http://harmattan-dev.nokia.com/unstable/beta2/harmattan-sdk-setup.py
    $ chmod +x harmattan-sdk-setup.py
    $ sudo ./harmattan-sdk-setup.py admininstall

Post install:  logout / login to get user access to /scratchbox/login or run
`newgrp sbox`.

Verify by writing `/scratchbox/login`  (CTRL+D to exit)

Sync `resolv.conf` and `host.conf` for network access in Scratchbox:

    $ sudo /scratchbox/sbin/sbox_sync

2. Do the following to prepare your environment

    $ mkdir /scratchbox/users/$USER/home/$USER/swork
    $ ln -s /scratchbox/users/$USER/home/$USER/swork ~/swork

NB: You don't need the explicit swork directory as long as the script directory resides on the same level as the source directories.

You should now have a working dir (~/swork), residing in/accessible from Scratchbox, linked in the root of your user root.

(outside Scratchbox)

    $ cd ~/swork
    $ git clone git@github.com:larsgk/browser-scripts.git
    $ browser-scripts/builddeps-install.sh
    $ browser-scripts/clone-sources.sh
    $ browser-scripts/build-sources.sh

This should install the necessary dependencies and fetch the sources needed.

In order to get git installed inside Scratchbox please follow these steps:

    sudo echo "deb http://scratchbox.org/debian harmattan main" >> /etc/apt/sources.list.d/sb.list
    sudo apt-get update
    sudo apt-get install scratchbox-devkit-git

Add this to your `PATH` inside Scratchbox:

    /scratchbox/devkits/git/bin

create-icecc-env.sh
-------------------

This script creates a tarball of your current toolchain environment for use with
icecc. The script outputs the information that you'll have to copy to your
`~/.bashrc` file in either your host environment or scratchbox environment.
