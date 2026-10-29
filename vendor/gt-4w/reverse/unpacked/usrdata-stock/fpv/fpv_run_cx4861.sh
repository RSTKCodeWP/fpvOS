#!/bin/sh

board_type=$1
board_ver=$2
rf_board=0
#bb_board_type=4, -- 8030 GPIOB_0=0.9v


function power_up_8030()
{
	echo 1 > /sys/class/gpio/gpio62/value
	usleep 500000
	return 0
}
function power_down_8030()
{
	echo 0 > /sys/class/gpio/gpio62/value
	usleep 500000
	return 0
}
function reset_8030()
{
	echo 1 > /sys/class/gpio/gpio59/value
	usleep 500000
	echo 0 > /sys/class/gpio/gpio59/value
	usleep 500000
	echo 1 > /sys/class/gpio/gpio59/value
	usleep 1000
	return 0
}
function fpv_rf_boardtype()
{
	ID_0=`cat /sys/class/gpio/gpio61/value`
	ID_1=`cat /sys/class/gpio/gpio60/value`
	bb_hw=$1

	echo "GPIO7_5, ID_0=$ID_0"
	echo "GPIO7_4, ID_1=$ID_1"
	echo "bb_hw=$bb_hw"
	
	if [ $bb_hw == 4 ];then
		#AR8032S GPIOB_0 = 0.9V
		if [ $ID_0 == 0 ] && [ $ID_1 == 1 ]; then
			#6.x, cx420-3600(3300)
			rf_board=96
			return 96
		elif [ $ID_0 == 1 ] && [ $ID_1 == 0 ]; then
			#7.x,CX426-RF-triband
			rf_board=112
			return 112
		elif [ $ID_0 == 1 ] && [ $ID_1 == 1 ]; then
			#8.x, CX424-RF-3.3G&5.8GHz
			rf_board=128
			return 128
		else
			#5.x,cx429
			rf_board=80
			return 80
		fi
	fi
	if [ $bb_hw == 5 ];then
		if [ $ID_0 == 1 ] && [ $ID_1 == 1 ]; then
			#a.x, CX424-RF-3.3G&5.8GHz,V1.1
			rf_board=160
			return 160
		else
			#9.x,CX428-RF-1.3G
			rf_board=144
			return 144
		fi
	fi
	#AR8032S GPIOB_0 <0.9V
	if [ $ID_0 == 0 ] && [ $ID_1 == 1 ]; then
		#2.x,CX420-RF-5500M
		rf_board=32
		return 32
	elif [ $ID_0 == 1 ] && [ $ID_1 == 0 ]; then
		#3.x, CX420-RF-6500M
		rf_board=48
		return 48
	elif [ $ID_0 == 1 ] && [ $ID_1 == 1 ]; then
		#
		rf_board=64
		return 64
	else
		#1.x, CX486-RF-4PA_V2.X
		rf_board=16
		return 16
	fi
	rf_board=0
	return 0
}
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

echo "run ...cx486"
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
devmem 0x11130050 32 0x1105
devmem 0x11130054 32 0x1105
#devmem 0x1113004c 32 0x1106
devmem 0x11130048 32 0x1106
devmem 0x11130044 32 0x1202

#UART1
devmem 0x11130030 32 0x1205
devmem 0x11130034 32 0x1205

#lsadc ch1
devmem 0x11130000 32 0x1004

echo 0 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio0/direction

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

#
#46 pin(GPIO7_0,0x17940090)
echo 56 > /sys/class/gpio/export                 
echo in > /sys/class/gpio/gpio56/direction 
#echo 0 > /sys/class/gpio/gpio56/value

#45 pin(GPIO7_1,0x17940094)
echo 57 > /sys/class/gpio/export                 
echo in > /sys/class/gpio/gpio57/direction 
#echo 1 > /sys/class/gpio/gpio57/value

let pin1=$(cat /sys/class/gpio/gpio56/value)
let pin2=$(cat /sys/class/gpio/gpio57/value)
echo $pin1,$pin2

CHIP_ID_REG_ADDR=0x11020EE0
CHIP_ID_CV610_20S=0x3516C613
CHIP_ID_CV610_10B=0x3516C610
CHIP_ID_CV610_00S=0x3516C616
CHIP_ID_CV610_20S_V1=0x24a13
CHIP_ID_CV610_10B_V1=0x24a10
CHIP_ID_CV610_00S_V1=0x24a16
CHIP_ID=$(devmem $CHIP_ID_REG_ADDR 32)
if [ "$CHIP_ID" = "$CHIP_ID_CV610_00S" ] || [ "$CHIP_ID" = "$CHIP_ID_CV610_00S_V1" ]; then
	if [ $pin1 == 1 ];then
		board_ver=17
	else
		board_ver=16
	fi
else
	if [ $pin1 == 1 ] && [ $pin2 == 1 ];then
		board_ver=17
	else
		board_ver=16
	fi
fi
echo "CHIP_ID=$CHIP_ID, board_type=$board_type, board_ver=$board_ver"

#20 pin (GPIO7_6,0x111c004c)
echo 62 > /sys/class/gpio/export                 
echo out > /sys/class/gpio/gpio62/direction 
#echo 1 > /sys/class/gpio/gpio62/value
power_down_8030
sleep 0.1
power_up_8030

#48pin(GPIO7_3) reset 8030
echo 59 > /sys/class/gpio/export                 
echo out > /sys/class/gpio/gpio59/direction 
reset_8030

#this sleep for wait 8032 rst done

#19pin (gpio7_5,gpio61) rf_gpio_ID0
echo 61 > /sys/class/gpio/export 
echo in > /sys/class/gpio/gpio61/direction 
#18pin (gpio7_4, gpio60) rf_gpio_ID1
echo 60 > /sys/class/gpio/export 
echo in > /sys/class/gpio/gpio60/direction 

/usrdata/fpv/ar_fpvhs_boardtype --hwver
HW_VER=$?
echo "------>SKY HW_VER=$HW_VER"

cd /usrdata/fpv/boot_ar8030
./boot_ar8030.sh 0
sleep 3

cd /usrdata/fpv
./daemon_sdiov12 -i 1 &
sleep 0.1

./ar_ldyhs_sky --bb_hw_id
bb_hw_id=$?
#[todo] tmp force to 4 for dbgcx422,cx420-3600
#tmp force to 4 for dbgcx420_5500_4w
#bb_hw_id=4

fpv_rf_boardtype $bb_hw_id
#rf_board=$?
echo "rf_board = $rf_board"

killall daemon_sdiov12
#reset 8030
power_down_8030
rmmod artosyn_sdio.ko
power_up_8030
#

cd /usrdata/fpv/boot_ar8030
./boot_ar8030.sh $rf_board 1 &
/usrdata/fpv/ar_fpvhs_upgrade -c 1 -m 1 -b $HW_VER -r $rf_board -t $board_type -e $board_ver &

sleep 2

echo 2 > /proc/irq/49/smp_affinity
echo 2 > /proc/irq/35/smp_affinity

rm -rf /usrdata/fpv/daemon_log/*

cd /usrdata/fpv/boot_ar8030
./boot_ar8030.sh $rf_board
sleep 3

telnetd &

cd /usrdata/fpv
./daemon_sdiov12 -i 1 &
sleep 0.1

#exit

./ar_ldyhs_sky  --board_type $board_type --board_ver $board_ver --rf_board $rf_board &
./ar_fpvhs_mp_service --hwver $HW_VER --board_type $board_type&

