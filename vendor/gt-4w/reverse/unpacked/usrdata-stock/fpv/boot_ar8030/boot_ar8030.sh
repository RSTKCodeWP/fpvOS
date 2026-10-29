#!/bin/sh

#$2=1, no need insmod artosyn_sdio.ko
echo -n "/usrdata/fpv/boot_ar8030" > /sys/module/firmware_class/parameters/path
RF_BOARD_TYPE=$(($1 >> 4))
echo $RF_BOARD_TYPE
if [ $RF_BOARD_TYPE == 2 ];then
    echo "CX420-RF-5500"
    bb_fw=bb_demo_sky_cx420_5500.img
    bb_cfg=bb_config_sky_cx420_5500.json
elif [ $RF_BOARD_TYPE == 3 ];then
    echo "CX420-RF-6500"
    bb_fw=bb_demo_sky_cx420_6500.img
    bb_cfg=bb_config_sky_cx420_6500.json
elif [ $RF_BOARD_TYPE == 4 ];then
    echo "CX420-RF-6000"
    bb_fw=bb_demo_sky_cx420_6000.img
    bb_cfg=bb_config_sky_cx420_6000.json
elif  [ $RF_BOARD_TYPE == 5 ];then
    echo "CX429"
    bb_fw=bb_demo_sky_cx429.img
    bb_cfg=bb_config_sky_cx429.json
elif [ $RF_BOARD_TYPE == 6 ];then
    echo "CX420-RF-5500-4w"
    bb_fw=bb_demo_sky_cx420_5500_4w.img
    bb_cfg=bb_config_sky_cx420_5500_4w.json
elif  [ $RF_BOARD_TYPE == 7 ];then
    echo "CX426"
    bb_fw=bb_demo_sky_cx426.img
    bb_cfg=bb_config_sky_cx426.json

elif  [ $RF_BOARD_TYPE == 8 ];then
    echo "CX424,3.3G & 5.8G"
    bb_fw=bb_demo_sky_cx424.img
    bb_cfg=bb_config_sky_cx424.json
elif [ $RF_BOARD_TYPE == 9 ];then
    echo "CX428-RF-1.3G"
    bb_fw=bb_demo_sky_cx428.img
    bb_cfg=bb_config_sky_cx428.json
elif [ $RF_BOARD_TYPE == 10 ];then
    echo "CX424-RF-3.3G&5.8GHz V1.1"
    bb_fw=bb_demo_sky_cx424.img
    bb_cfg=bb_config_sky_cx424_v11.json
else
    echo "CX486-RF-4PA"
    bb_fw=bb_demo_sky_3v3.img
    bb_cfg=bb_config_sky.json
fi

#upgrade pc tool get set bb power use
echo "$(pwd)/$bb_cfg" > /tmp/bb_cfg_path

if [ "$2" = "1" ]; then
	echo "Skip insmod artosyn_sdio.ko (parameter 2 is 1)"
    exit 0
else
	insmod artosyn_sdio.ko fw_name=$bb_fw cfg_name=$bb_cfg
fi




