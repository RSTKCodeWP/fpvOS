#!/bin/sh

ifconfig lo up

ifconfig usb0 down
ifconfig usb0 hw ether 00:23:11:06:90:04
ifconfig usb0 192.168.3.104 netmask 255.255.255.0
route add default gw 192.168.3.204
ifconfig usb0 up


