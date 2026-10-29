#!/bin/sh

board_type=$1
board_ver=$2
echo "board_type=$board_type, board_ver=$board_ver"

TEMP_SCRIPT="/usrdata/fpv/temp_measure.sh 1"
while true; do
    temperature=$($TEMP_SCRIPT)

    if [ "$temperature" -lt 1050 ]; then
        echo "Temperature is $temperature. Continuing..."
        break
    else
        echo "Temperature is $temperature, over 105℃, waiting cooling..."
    fi
	sleep 1
done

function rf_board_get_sub_ver()
{
    #gpio 7_0 and gpio7_1
    let pin1=$(cat /sys/class/gpio/gpio56/value)
    let pin2=$(cat /sys/class/gpio/gpio57/value)
    echo $pin1,$pin2
    if [ $pin1 == 0 ] && [ $pin2 == 1 ];then
        #v1.1
		return 17
	else
        #v1.0
		return 16
	fi
}

echo "run ..."
#cat /sys/class/mmc_host/mmc0/mmc0\:0001/device

echo 4096 > /proc/sys/vm/min_free_kbytes
echo 200 > /proc/sys/vm/watermark_scale_factor
echo 10 > /proc/sys/vm/watermark_scale_factor
rm -rf /usrdata/fpv/daemon_log/*

#SD0_detect, not use as gpio
devmem 0x10260028 32 0x1130
#SD0, io, cmd, clk
#devmem 0x1026002c 32 0x1101
#devmem 0x10260030 32 0x1101
#devmem 0x10260034 32 0x1201
#devmem 0x10260038 32 0x1101
#devmem 0x1026003c 32 0x1101
#devmem 0x10260040 32 0x1101

#gpio pin_mux misc do by sys_config.ko

#PINMUX, GPIO7_3, ar8030_rst
#devmem 0x17940088 32 0x1200
#as output
#devmem 0x11097400 32 0x08
#devmem 0x11097020 32 0x00
#sleep 0.1
#devmem 0x11097020 32 0xff

#SPI0 pinmux
devmem 0x11130050 32 0x1106
devmem 0x11130054 32 0x1106
devmem 0x1113004c 32 0x1106
devmem 0x11130048 32 0x1106
devmem 0x11130044 32 0x1202

#UART1
devmem 0x11130030 32 0x1205
devmem 0x11130034 32 0x1205

echo 0 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio0/direction

echo 56 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio56/direction
echo 57 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio57/direction


ifconfig lo up
cd /usrdata/fpv

if [ -e "/factory/run_rndis_flag" ]; then
	echo "start config_ether.sh"
    ./config_ether.sh &
    rm -f "/factory/run_rndis_flag"
	sync
else
	echo "start config_serial.sh"
    ./config_serial.sh $board_type &
fi

rf_board_get_sub_ver
#rf_board=16
rf_board=$?
echo "rf board=$rf_board"

/usrdata/fpv/ar_fpvhs_boardtype --hwver
HW_VER=$?
echo "------>SKY HW_VER=$HW_VER"

/usrdata/fpv/ar_fpvhs_upgrade -c 1 -m 1 -b $HW_VER -r $rf_board -t $board_type -e $board_ver &

sleep 1
cd /usrdata/fpv/ko_cv610_20s/load3516cv610
./fpv_load3516cv610_20s_debug -i &

#LED_R,gpio7_7
echo 63 > /sys/class/gpio/export 
echo out > /sys/class/gpio/gpio63/direction 
echo 1 > /sys/class/gpio/gpio63/value
#LED_G,gpio1_0
echo 8 > /sys/class/gpio/export                  
echo out > /sys/class/gpio/gpio8/direction 
echo 1 > /sys/class/gpio/gpio8/value


#this sleep for wait 8032 rst done
sleep 2

echo 2 > /proc/irq/49/smp_affinity
echo 2 > /proc/irq/35/smp_affinity

rm -rf /usrdata/fpv/daemon_log/*

cd /usrdata/fpv/boot_ar8030
./boot_ar8030.sh $board_type $rf_board
sleep 3

telnetd &

cd /usrdata/fpv

./daemon_sdiov12 -i 1&
sleep 0.1


./ar_ldyhs_sky --board_type $board_type --board_ver $board_ver &
./ar_fpvhs_mp_service --hwver $HW_VER --board_type $board_type & 



