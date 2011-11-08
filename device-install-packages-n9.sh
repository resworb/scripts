# install missing packages

# this script assumes that the N9 is connected via usb networking - with the name "device"

set -e

SBCMD=/scratchbox/login

$SBCMD fakeroot apt-get -d install --reinstall -y --force-yes libxcb-image0 libxcb-keysyms1 libxcb-icccm1 libxcb-aux0 libxcb-event1 libxcb-property1 libxcb-atom1

mkdir -p ~/swork/packages && cd ~/swork/packages

echo "cp /var/cache/apt/archives/libxcb-image0_* ~/swork/packages/" > copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-keysyms1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-icccm1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-aux0_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-atom1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-event1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-property1_* ~/swork/packages/" >> copypackages.sh
chmod +x copypackages.sh

$SBCMD -d $HOME/swork/packages ./copypackages.sh

INSTALL_CMD="cd packages && dpkg -i *.deb" 

scp -r $HOME/swork/packages root@device:.
 
ssh root@device "${INSTALL_CMD}"

echo "Done."


