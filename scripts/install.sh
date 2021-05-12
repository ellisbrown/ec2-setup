#!/bin/bash

sudo apt-get update
sudo apt-get upgrade -y

# Install Lubuntu
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y lubuntu-desktop

# xterm is needed for xinit
sudo apt-get install -y xterm

export SYS_ARCH=amd64  # amd64

# Install VirtualGL
sudo apt-get install libglu1-mesa  # required for virtualgl

export VGL_VERSION=2.6.5  #2.5.2
wget https://sourceforge.net/projects/virtualgl/files/$VGL_VERSION/virtualgl_${VGL_VERSION}_$SYS_ARCH.deb/download -O virtualgl_${VGL_VERSION}_$SYS_ARCH.deb && \
sudo dpkg -i virtualgl*.deb && \
rm virtualgl*.deb

# Install TurboVNC
export TVNC_VERSION=2.2.6  # 2.1.1
wget https://sourceforge.net/projects/turbovnc/files/$TVNC_VERSION/turbovnc_${TVNC_VERSION}_$SYS_ARCH.deb/download -O turbovnc_${TVNC_VERSION}_$SYS_ARCH.deb && \
sudo dpkg -i turbovnc*.deb && \
rm turbovnc*.deb

# Install noVNC
sudo git clone https://github.com/novnc/noVNC /opt/noVNC && \
sudo git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Configure VirtualGL
sudo /etc/init.d/lightdm stop
sudo /opt/VirtualGL/bin/vglserver_config -config +s +f -t
#sudo /etc/init.d/lightdm start

# Instead of exit - we'll update kernel and headers to prepare for Nvidia drivers install.
sudo apt-get install -y gcc linux-headers-$(uname -r)
sudo apt-get upgrade -y linux-aws

# Cleanup
sudo apt-get clean && \
sudo apt-get autoremove -y && \
sudo rm -r /var/lib/apt/lists/*

# Add aliases
echo "alias cp=\"cp -i\"" >> ~/.bash_aliases
echo "alias mv=\"mv -i\"" >> ~/.bash_aliases
echo "alias rm=\"rm -i\"" >> ~/.bash_aliases

echo ""
echo "******************************************************************"
echo "*                                                                *"
echo "* Rebooting for changes to take effect!                          *"
echo "*                                                                *"
echo "******************************************************************"
echo ""

sudo reboot
