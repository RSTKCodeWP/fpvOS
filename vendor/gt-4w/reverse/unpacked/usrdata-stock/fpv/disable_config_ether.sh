#!/bin/sh

cd /sys/kernel/config/usb_gadget/ether 
echo > UDC 
rm configs/c.1/rndis.usb0 
rmdir configs/c.1/strings/0x409 
rmdir functions/rndis.usb0 
rm os_desc/c.1 
rmdir configs/c.1 
rmdir strings/0x409 
cd ../ 
rmdir ether 
cd /root/ 
umount /sys/kernel/config/