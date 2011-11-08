# install missing packages

SBCMD=/scratchbox/login

$SBCMD fakeroot apt-get -d install libxcb-image0 libxcb-keysyms1 libxcb-icccm1 libxcb-aux0 libxcb-event1 libxcb-property1

mkdir -p ~/swork/packages && cd ~/swork/packages

echo "cp /var/cache/apt/archives/libxcb-image0_* ~/swork/packages/" > copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-keysyms1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-icccm1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-aux0_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-event1_* ~/swork/packages/" >> copypackages.sh
echo "cp /var/cache/apt/archives/libxcb-property1_* ~/swork/packages/" >> copypackages.sh
chmod +x copypackages.sh

$SBCMD -d $HOME/swork/packages ./copypackages.sh

INSTALL_CMD="cd /nfs$HOME/swork/packages && dpkg -i *.deb" 

ssh user@device "${INSTALL_CMD}"
