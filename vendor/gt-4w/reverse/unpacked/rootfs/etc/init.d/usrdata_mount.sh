#!/bin/sh

#param: $1:  flash_type
#       $2:  nor: mtdblockN
#            mcp: N means the mtdN
#            mmcblkNpM:  N: 0 or 1, means mmc0, mmc1


echo "mounting $1:$2 to usrdata"

if [ $2 == null ]; then
	exit
fi

if [ $1 == nor ]; then
	mount -t squashfs /dev/$2 /usrdata
	if [ $? -ne 0 ]; then
		mount -t jffs2 /dev/$2 /usrdata
	fi
elif [ $1 == nand ]; then
	#mount -t ubifs /dev/$2 /usrdata
	ubiattach -m $2 -d $2 /dev/ubi_ctrl
	mount -t ubifs /dev/ubi$2_0 /usrdata

elif [ $1 ==  mmc0 ] || [ $1 == mmc1 ]; then
	mount -t ext4 /dev/$2 /usrdata
fi
