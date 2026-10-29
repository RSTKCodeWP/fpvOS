#!/bin/sh

/usrdata/fpv/fpv_sync_mp_cfg.sh

insmod /usrdata/fpv/ko_cv610_20s/ot_osal.ko proc_show=1
insmod /usrdata/fpv/ko_cv610_20s/ot_adc.ko

/usrdata/fpv/ar_adc_mv_read_hs chn 1
sleep 0.1
/usrdata/fpv/ar_adc_mv_read_hs chn 1

ch1_mv=$(cat /tmp/socadc_val.txt  | grep -r adc -m 1 -w | cut -d = -f 2)
echo "adc_voltage=($ch1_mv)mv"

#board_type define, all app use this value, do not change!!!
#cx4861 is cx486 single cv610 version; cx4862 is cx486 double cv610 version
BT_CX482=482
BT_CX4861=4861
BT_CX4862=4862
BT_CX492=492
BT_CX472=472
BT_CX486_GT_M=4861_GT_M
#board version, from v1.0 start, v1.0=0x10 v1.2=0x12, etc...
board_ver=16

if [ $ch1_mv -ge 0 ] && [ $ch1_mv -lt 150 ]; then
	#0<=0<0.15
	#echo "sky_cx4861"
	board_type=$BT_CX4861
elif [ $ch1_mv -ge 1500 ] && [ $ch1_mv -lt 1800 ]; then
	#1.5<=1.65<1.8
	board_type=$BT_CX482
elif [ $ch1_mv -ge 450 ] && [ $ch1_mv -lt 750 ]; then
	#0.45<=0.6<0.75
	board_type=$BT_CX492
elif [ $ch1_mv -ge 750 ] && [ $ch1_mv -lt 1005 ]; then
	#0.75<=0.6<1.05
	board_type=$BT_CX472
else
	echo "no match, use default board_type=sky_cx482"
	board_type=$BT_CX482
fi

if [ -e "/usrdata/fpv/flag_force_run_cx482" ]; then
	echo "force to cx482"
	board_type=$BT_CX482
elif [ -e "/usrdata/fpv/flag_force_run_cx4861" ]; then
	echo "force to cx4861"
	board_type=$BT_CX4861
elif [ -e "/usrdata/fpv/flag_force_run_cx4862" ]; then
	echo "force to cx4862"
	board_type=$BT_CX4862
elif [ -e "/usrdata/fpv/flag_force_run_cx492" ]; then
	echo "force to cx492"
	board_type=$BT_CX492
elif [ -e "/usrdata/fpv/flag_force_run_cx4861_GT_M" ]; then
	echo "force to cx486_GT_M"
	board_type=$BT_CX486_GT_M
fi

fpv_board_type_file="/usrdata/fpv/fpv_board_type"
board_type_cur_val=$(cat "$fpv_board_type_file" 2>/dev/null)
if [ "$board_type_cur_val" != "$board_type" ]; then
	echo "$board_type" > /usrdata/fpv/fpv_board_type
	sync
else
	echo "board type same, fpv_board_type_file no need update"
fi
echo "===== sky: board_type=$board_type, board_ver=$board_ver ====="

cd /usrdata/fpv
if [ $board_type == $BT_CX482 ]; then
	echo "cx482 run start...."
	./fpv_run_cx482.sh $board_type $board_ver
elif [ $board_type == $BT_CX4861 ]; then
	echo "cx486 run start...."
	./fpv_run_cx4861.sh $board_type $board_ver
elif [ $board_type == $BT_CX4862 ]; then
        echo "cx4862 run start...."
        ./fpv_run_cx4862.sh $board_type $board_ver
elif [ $board_type == $BT_CX492 ]; then
	echo "cx492 run start...."
	./fpv_run_cx482.sh $board_type $board_ver
elif [ $board_type == $BT_CX472 ]; then
	echo "cx472 run start...."
	./fpv_run_cx482.sh $board_type $board_ver
elif [ $board_type == $BT_CX486_GT_M ];then
	echo "cx4861_GT_M"
	./fpv_run_cx486_GT_M.sh $BT_CX4861 $board_ver
else
	echo "should not happen, default cx482 run start...."
	./fpv_run_cx482.sh $board_type $board_ver
fi

