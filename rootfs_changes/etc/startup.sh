#!/bin/sh
#
# startup.sh
#
######################################################
# Script to do get some stuff done before logging in.#
######################################################
echo 9 > /proc/sys/kernel/printk
if [ -f "/swapfile" ]; then
echo "swapfile exists"  > /dev/kmsg
else
echo "#############################################################################################" > /dev/kmsg
echo "################## First start please be patient we have to do some things ##################" > /dev/kmsg
echo "#############################################################################################" > /dev/kmsg
echo "**** create swapfile"  > /dev/kmsg
dd if=/dev/zero of=/swapfile bs=1024 count=524288
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile
echo "/swapfile\tswap\tswap\tdefaults\t0\t0" >> /etc/fstab
swapon /swapfile
echo "**** Reinstall libgdk-pixbuf2.0-0"  > /dev/kmsg
dpkg -i /libgdk-pixbuf2.0-0_2.24.0-1ubuntu1_armel.deb
echo "**** Remove network manager we will be using wicd"  > /dev/kmsg
apt-get -y remove network-manager
fi

if [ -d "/lib/modules/2.6.37.6+/extra" ]; then
echo "**** SGX modules exists" > /dev/kmsg
else
echo "**** Installing SGX" > /dev/kmsg
/etc/init.d/omap-demo
depmod -a
echo "#############################################################################################" > /dev/kmsg
echo "##################              All done going to reboot now :)            ##################" > /dev/kmsg
echo "#############################################################################################" > /dev/kmsg
reboot
fi
echo "mount /dev/mmcblk1p2 on /media/squashfs"
if [ -d "/media/squashfs" ]; then
 echo "squashfs exists"
else
mkdir /media/squashfs
fi
mount /dev/mmcblk1p2 /media/squashfs

echo "Mount the android squashfs to steal some modules and other stuff :)"
if [ -d "/android" ]; then
 echo "android exists"
else
mkdir /android
fi
mount -o loop,offset=256 /media/squashfs/androidmerged.squashfs.secure /android
if [ -d "/media/data" ]; then
 echo "/media/data exists"
else
mkdir /media/data
fi

#echo "mount /dev/mmcblk1p4 on /media/data"
#mount /dev/mmcblk0p4 /media/data
#echo "copy the ini file and calibration file needed for wifi"
#if [ -f "/wifi/wlanconf.nvs" ]; then
# echo "/wifi/wlanconf.nvs exists"
#else
#cp /media/data/misc/wifi/wlanconf.nvs /wifi
#fi
#if [ -f "/wifi/tiwlan.ini" ]; then
# echo "/wifi/tiwlan.ini exists"
#else
#cp /media/data/misc/wifi/tiwlan.ini /wifi
#fi
#echo "Enable wifi on startup"
echo "**** Get wifi up"  > /dev/kmsg
ifconfig wlan0 hw ether 00:16:dc:62:88:97
ifconfig wlan0 up
#iwconfig wlan0 essid Maurice2
#dhclient wlan0
#chmod 0777 /sys/module/hid_multitouch/parameters/*
#echo Y > /sys/module/hid_multitouch/parameters/rotate180

echo "**** load module for usb ethernet" > /dev/kmsg
modprobe g_cdc

echo "**** load bluetooth" > /dev/kmsg
while true
do

	modprobe btwilink
	sleep 10	# Wait while it miserably fails to install "line disc".
	hciattach -n /dev/ttyS0 texas 3000000
	rmmod btwilink
done &

exit 0

