#!/bin/sh

VID="0x1D6B"
PID="0x0002"
MANUFACTURER="Vendor"
PRODUCT="Ethernet"
SERIALNUMBER="123456789012"

# 默认路径
USB_IP_SCRIPT="/usrdata/fpv/usb_ip.sh"
# 如果第一个参数是 clean，则使用 /tmp/usb_ip.sh
if [ "$1" = "clean" ]; then
    USB_IP_SCRIPT="/tmp/usb_ip.sh"
fi

#echo device > /proc/10300000.usb20drd/mode
#sleep 1

mount -t configfs none /sys/kernel/config/
cd /sys/kernel/config/usb_gadget/
mkdir ether
cd ether/
echo "0x0200" > bcdUSB
echo "0xef" > bDeviceClass
echo "2" > bDeviceSubClass
echo $VID > idVendor
echo $PID > idProduct
echo "0x3000" > bcdDevice
echo "0x01" > bDeviceProtocol
mkdir strings/0x409
echo $MANUFACTURER > strings/0x409/manufacturer
echo $PRODUCT > strings/0x409/product
echo $SERIALNUMBER > strings/0x409/serialnumber
mkdir configs/c.1
echo "0xC0" > configs/c.1/bmAttributes
echo "1" > configs/c.1/MaxPower
mkdir configs/c.1/strings/0x409/
echo "RNDIS" > configs/c.1/strings/0x409/configuration
echo "1" > os_desc/use
echo "0xcd" > os_desc/b_vendor_code
echo "MSFT100" > os_desc/qw_sign
mkdir functions/rndis.usb0
echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
ln -s functions/rndis.usb0 configs/c.1
ln -s configs/c.1 os_desc
echo "$(ls /sys/class/udc/)" > UDC

# 执行 usb ip 脚本
if [ -x "$USB_IP_SCRIPT" ]; then
    "$USB_IP_SCRIPT"
else
    echo "Warning: $USB_IP_SCRIPT not found or not executable"
fi



