#!/bin/bash

# Download the GRID driver installation utility
sudo apt install awscli -y
aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .
chmod +x NVIDIA-Linux-x86_64*.run

sudo service lightdm stop
sudo /bin/bash NVIDIA-Linux-x86_64*.run --no-questions --run-nvidia-xconfig
rm -f *.run

# Edit /etc/X11/xorg.conf - See https://stackoverflow.com/questions/34805794/virtualgl-and-turbovnc-extension-glx-missing-on-display-0-0
# sudo nano /etc/X11/xorg.conf
# And under the "Device" section:
# BusID          "0:3:0"
# So must add under the "Screen" section:
# Option         "UseDisplayDevice" "none"


sudo touch /etc/X11/xorg.conf  # ensure exists
sudo awk '/VendorName     \"NVIDIA Corporation\"/{print;print "    BusID          \"0:3:0\"";next}1' /etc/X11/xorg.conf > tmp && \
sudo mv tmp /etc/X11/xorg.conf
sudo awk '/DefaultDepth    24/{print;print "    Option        \"UseDisplayDevice\" \"none\"";next}1' /etc/X11/xorg.conf > tmp && \
sudo mv tmp /etc/X11/xorg.conf

echo ""
echo "******************************************************************"
echo "*                                                                *"
echo "* Rebooting for changes to take effect!                          *"
echo "*                                                                *"
echo "******************************************************************"
echo ""

sudo reboot
