#!/bin/sh

# read BOARD_TYPE value
BOARD_TYPE=$(grep '^BOARD_TYPE=' /etc/app.version | cut -d= -f2)

#case "$BOARD_TYPE" in
#    "Sky486")
#        export VID="0x1D74"
#        ;;
#    "Sky482")
#        export VID="0x1D6D"
#        ;;
#    *)
#		export VID="0x1D6D"
#        echo "invalid: $BOARD_TYPE, default 482" >&2
#        ;;
#esac

board_type=$1

#GND: CX10-CX1F SKY: CX20-CX4F  RELAY: CX50-CX5F
map_board_type() {
    local board_name=""
    case $board_type in
        "401")
            board_name="CX10"
            ;;
        "485")
            board_name="CX11" 
            ;;
        "482")
            board_name="CX20" 
            ;;
        "4861")
            board_name="CX21"
            ;;
        "4862")
            board_name="CX22"
            ;;
        "492")
            board_name="CX23"
            ;;
        "472")
            board_name="CX24"
            ;;
        "4861_GT_M")
            board_name="CX25"
            ;;
        "489")
            board_name="CX50"
            ;;
        *)
            echo "error: unkonwn $board_type" >&2
            return 1
            ;;
    esac
    
    echo "$board_name"
    return 0
}

mapped_board_name=$(map_board_type $board_type)
echo "mapped_board_name=$mapped_board_name"

VID="0x1D76"
echo "#set usb vid=$VID"

export PID="0x0101"
export MANUFACTURER="Vendor"
export PRODUCT="SerialGadget"
if [ -n "$mapped_board_name" ]; then
    export SERIALNUMBER="$mapped_board_name"
else
    export SERIALNUMBER="123456789012"
fi

mount -t configfs none /sys/kernel/config/
cd /sys/kernel/config/usb_gadget/
mkdir acm
cd acm
mkdir functions/acm.0
echo $VID > idVendor
echo $PID > idProduct

echo "2" > bDeviceClass
mkdir strings/0x409
echo $MANUFACTURER > strings/0x409/manufacturer
echo $PRODUCT > strings/0x409/product
echo $SERIALNUMBER > strings/0x409/serialnumber
mkdir configs/c.1/
echo "1" > configs/c.1/MaxPower
echo "0xC0" > configs/c.1/bmAttributes
mkdir configs/c.1/strings/0x409/
echo "CDC ACM config" > configs/c.1/strings/0x409/configuration
ln -s functions/acm.0/ configs/c.1/
echo "$(ls /sys/class/udc/)" > UDC

