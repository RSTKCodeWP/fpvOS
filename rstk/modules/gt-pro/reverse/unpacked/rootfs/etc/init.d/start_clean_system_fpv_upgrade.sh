#!/bin/sh

rtfs_dir="/tmp"

get_board_type() {
    local board_type=""
    
    if [ -r "/usrdata/fpv/fpv_board_type" ]; then
        board_type=$(cat /usrdata/fpv/fpv_board_type 2>/dev/null | tr -d '\n\r')
        if [ -n "$board_type" ]; then
            echo "Read board type from file: $board_type" >&2
            echo "$board_type"
            return 0
        fi
    fi

	echo "Read board type from file error" >&2
    return 1
}

BOARD_TYPE=$(get_board_type "$@")

#20 pin (GPIO7_6,0x111c004c) RF_PWR_EN_3V3
echo 62 > /sys/class/gpio/export                 
echo out > /sys/class/gpio/gpio62/direction 
echo 0 > /sys/class/gpio/gpio62/value

# cp /usr/bin
cp /usrdata/fpv/fpv_board_type $rtfs_dir
cp /usrdata/fpv/config_serial.sh $rtfs_dir
cp /usrdata/fpv/disable_config_serial.sh $rtfs_dir
cp /usrdata/fpv/config_ether.sh $rtfs_dir
cp /usrdata/fpv/disable_config_ether.sh $rtfs_dir
cp /usrdata/fpv/usb_ip.sh $rtfs_dir
cp /usrdata/fpv/ar_fpvhs_upgrade $rtfs_dir
cp /sbin/reboot $rtfs_dir


cd /usrdata/fpv/ko_cv610_20s/load3516cv610
./fpv_load3516cv610_20s_debug -i &

#umount /usrdata/
#umount /factory/

telnetd &

$rtfs_dir/config_serial.sh $BOARD_TYPE
ifconfig eth0 192.168.4.20 up

sleep 1
mkdir /tmp/pc
chmod 777 /tmp/pc

#ulimit -c unlimited
#echo "/tmp/coredump-%e-%p-%t" > /proc/sys/kernel/core_pattern

$rtfs_dir/ar_fpvhs_upgrade -c 0 -m 1 &

