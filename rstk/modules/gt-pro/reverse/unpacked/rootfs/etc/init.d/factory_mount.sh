#!/bin/sh

# mount factory partition to /factory, if failed, erase partition, mount again.


#param: $1:  flash_type
#       $2:  nor: mtdblockN
#            mcp: N means the mtdN
#            mmcblkNpM:  N: 0 or 1, means mmc0, mmc1

if [ $2 == null ]; then
	#create flag factory mount end flag in /run
	touch /run/factory_mount_end
	exit
fi

echo mounting factory flash_type=$1:$2

factory_ubi_part=$2

while true
do
	if [ $1 == nor ]; then
		echo "nor flash mounting factory"
		if [ ! -e /dev/$2 ]; then
			exit
		fi
		mount -t jffs2 /dev/$2 /factory
		#mount -o,ro,remount /factory
		if [ $? -ne 0 ]; then
			factory_nor_mtd=`echo $2 | sed 's/block//g'`
			/etc/flash_erase -j /dev/$factory_nor_mtd 0 0
		else
			break
		fi
	elif [ $1 == nand ]; then
		echo "mcp mounting factory"
		if [ ! -e /dev/mtd$2 ]; then
			exit
		fi
		ubiattach -m $2 -d $factory_ubi_part /dev/ubi_ctrl
		rm -rf /run/ubinfo.txt
		ubi_vol="ubi${factory_ubi_part}_0"
		echo $ubi_vol
		mount -t ubifs /dev/$ubi_vol /factory
		if [ $? -ne 0 ]; then
			sleep 1
			mount -t ubifs /dev/$ubi_vol /factory
		fi
		#mount -o,ro,remount /factory
		if [ $? -ne 0 ]; then
			ubidetach -d $factory_ubi_part /dev/ubi_ctrl
			/etc/ubiformat -y /dev/mtd$2
			ubiattach -m $2 -d $factory_ubi_part /dev/ubi_ctrl
			/etc/ubinfo /dev/ubi$factory_ubi_part > /run/ubinfo.txt
			count=`grep -r available /run/ubinfo.txt | cut -d ":" -f2 | cut -d " " -f2`
			echo $count
			let count=count-1
			echo $count
			/etc/ubimkvol /dev/ubi$factory_ubi_part -S $count -N factory
			ubidetach -d $factory_ubi_part /dev/ubi_ctrl
		else
			break
		fi
	elif [ $1 ==  mmc0 ] || [ $1 == mmc1 ]; then
		echo mounting $2 /factory
		if [ ! -e /dev/$2 ]; then
			exit
		fi
		mount -t ext4 /dev/$2 /factory
		#mount -o,ro,remount /factory
		if [ $? -ne 0 ]; then
			/etc/mkfs.ext4 /dev/$2
		else
			break
		fi
	fi
	sleep 3
done

exit
