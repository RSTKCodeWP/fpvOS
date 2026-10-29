#!/bin/sh

flashtype=null
userapp_part=null
usr_data_part=null
factory_part=null

fdisk_file=/run/fdisk.info

# check partition validity by bootargs part_info
# para1: partition index, each partition in the order corresponds to one bit
function partvalid()
{
	# 0: invalid, otherwise valid
	ret=`awk -v nbit="$1" -F '[ =]' '{i = 1; while (i <= NF) {if ($i == "part_info") {print and($(i + 1), lshift(1, nbit));} i++;}}' /proc/cmdline`
	if [ $ret == 0 ]; then
		echo "n"
	else
		echo "y"
	fi
}

# whether part_info exsit or not
if [ ! -z $part_info ]; then
	haspart_info=y
else
	haspart_info=n
fi

# Attention: part_info is ordered by ini file, and don't contain romcode, spl0, spl1, gpt
function get_mtd_valid_part() {
	# for exsample, part is mtd0, mtd1...
	part=`cat /proc/mtd | grep -r $1 -m 1 -w | cut -d : -f 1` 1>/dev/null 2>&1
	if [ ! -z $part ]; then
		if [ $haspart_info == y ]; then
			partnum=`echo $part | sed 's/mtd//g'` 1>/dev/null 2>&1
			if [ $flashtype == "nor" ]; then
				# part_info index from 0, but /proc/mtd from 5
				n=`expr $partnum - 5`
			elif [ $flashtype == "nand" ]; then
				# Attention: assume that user partitions are all in nand
				# mtd0 is the second line, the first line is dev: 	size ...,
				# cat /proc/mtd to see the details

				# part_info index from 0, but /proc/mtd from 6 + 1(spi0.xxx)
				n=`expr $partnum - 7`
			fi

			valid=$(partvalid $n)
			# invalid
			if [ $valid == n ]; then
				partnum=`expr $partnum + 1`
			fi

			echo "mtd"$partnum
		else
			echo $part
		fi
	fi
}

function get_fpv_dual_part_mtd_valid_part() {
	if [ -e /run/bootsel1 ]; then
		part=`cat /proc/mtd | grep -r $1"1" -m 1 -w | cut -d : -f 1` 1>/dev/null 2>&1
	else
		part=`cat /proc/mtd | grep -r $1"0" -m 1 -w | cut -d : -f 1` 1>/dev/null 2>&1
	fi
	echo $part
}

#get /dev/mtdN with get_mtd_char_dev
function get_mtd_char_dev() {
	usr_data_part=`cat /proc/mtd | grep -r usrdata -m 1 -w | cut -d : -f 1` 1>/dev/null 2>&1
	# dual part
	if [ -z $usr_data_part ]; then
		usr_data_part=$(get_fpv_dual_part_mtd_valid_part "usrdata")
	fi
	factory_part=`cat /proc/mtd | grep -r factory -m 1 -w | cut -d : -f 1` 1>/dev/null 2>&1
	# dual part
	if [ -z $factory_part ]; then
		factory_part=$(get_fpv_dual_part_mtd_valid_part "factory")
	fi
}

# use ubiattach command to attach mtd to ubi dev
# para1: mtdN
# para2: ubi number M
function ubi_attach_mtd_to_ubi() {
	if [ $# != 2 ]; then
		return 1
	else
		mtd_part_num=`echo $1 | sed 's/mtd//g'` 1>/dev/null 2>&1
		ubiattach -m $mtd_part_num -d $2 /dev/ubi_ctrl
	fi

	return $?
}

function nand_attach_mtd_to_ubi() {
	# nand using the ubi partition, ubiattach partition

	#ubi_attach_mtd_to_ubi $usr_data_part 7
	#if [ $? == 0 ]; then usr_data_part=ubi7_0;
	#else usr_data_part=null;
	#fi
	usr_data_part=`echo $usr_data_part | sed 's/mtd//g'` 1>/dev/null 2>&1
	if [ -z $usr_data_part ]; then usr_data_part=null
	fi

	factory_part=`echo $factory_part | sed 's/mtd//g'` 1>/dev/null 2>&1
	if [ -z $factory_part ]; then factory_part=null
	fi
}


function nor_mtd_to_mtdblock() {
	userapp_part=`echo $userapp_part | sed 's/mtd/mtdblock/g'` 1>/dev/null 2>&1
	if [ -z "$userapp_part" ]; then userapp_part=null; fi

	usr_data_part=`echo $usr_data_part | sed 's/mtd/mtdblock/g'` 1>/dev/null 2>&1
	if [ -z "$usr_data_part" ]; then usr_data_part=null; fi

	factory_part=`echo $factory_part | sed 's/mtd/mtdblock/g'` 1>/dev/null 2>&1
	if [ -z "$factory_part" ]; then	factory_part=null; fi
}

function get_mmc_valid_part() {
	part=`cat $fdisk_file | grep -r $1 -m 1 -w | sed 's/^[ \t]*//g' | cut -d " " -f 1` 1>/dev/null 2>&1
	if [ ! -z "$part" ]; then
		if [ $haspart_info == y ]; then
			# part_info index from 0, but fdisk from 1
			n=`expr $part - 1`
			valid=$(partvalid $n)
			# invalid
			if [ $valid == n ]; then
				part=`expr $part + 1`
			fi
		fi
		echo $part
	fi
}

#from fdisk_file, get mmc partition infor
get_mmc_block_dev() {
	if [ $1 == mmc0 ]; then
		fdisk /dev/mmcblk0 -l > $fdisk_file;
		mmc_prefix=mmcblk0p
	else
		fdisk /dev/mmcblk1 -l > $fdisk_file;
		mmc_prefix=mmcblk1p
	fi

	userapp_part=`cat $fdisk_file | grep -r userapp -m 1 -w | sed 's/^[ \t]*//g' | cut -d " " -f 1` 1>/dev/null 2>&1
	if [ -z "$userapp_part" ]; then userapp_part=null;
	else userapp_part="$mmc_prefix"$userapp_part;
	fi

	# check whether dual part
	if [ $userapp_part == null ]; then
		userapp_part=$(get_mmc_valid_part "userapp0")
		if [ -z "$userapp_part" ]; then userapp_part=null;
		else userapp_part="$mmc_prefix"$userapp_part;
		fi
	fi

	usr_data_part=`cat $fdisk_file | grep -r usr_data -m 1 -w | sed 's/^[ \t]*//g' | cut -d " " -f 1` 1>/dev/null 2>&1
	if [ -z "$usr_data_part" ]; then usr_data_part=null;
	else usr_data_part="$mmc_prefix"$usr_data_part;
	fi;

	# check whether dual part
	if [ $usr_data_part == null ]; then
		usr_data_part=$(get_mmc_valid_part "usr_data0")
		if [ -z "$usr_data_part" ]; then usr_data_part=null;
		else usr_data_part="$mmc_prefix"$usr_data_part;
		fi
	fi

	factory_part=`cat $fdisk_file | grep -r factory -m 1 -w | sed 's/^[ \t]*//g' | cut -d " " -f 1` 1>/dev/null 2>&1
	if [ -z "$factory_part" ]; then factory_part=null;
	else factory_part="$mmc_prefix"$factory_part;
	fi

	# check whether dual part
	if [ $factory_part == null ]; then
		factory_part=$(get_mmc_valid_part "factory0")
		if [ -z "$factory_part" ]; then factory_part=null;
		else factory_part="$mmc_prefix"$factory_part;
		fi
	fi

	echo userapp_part=$userapp_part usr_data_part=$usr_data_part factory_part=$factory_part
}


# get mtd parts information from /proc/mtd
# FIxme: can not get any information for emmc
function get_parts() {

	echo "get get_parts for flashtype=" $flashtype

	if [ $flashtype == nor ] || [ $flashtype == nand ]; then

		#if device type is nor or nand, get dev node from /proc
		get_mtd_char_dev

		#for qspi nor, replace mtd to mtdblock
		#for nand device, create ubi device use ubi_attach
		if [ $flashtype == nor ]; then
			nor_mtd_to_mtdblock
		else
			nand_attach_mtd_to_ubi
		fi
	elif [ $flashtype == mmc1 ] || [ $flashtype == mmc0 ]; then
		get_mmc_block_dev $flashtype
	fi
}

function get_flashtype() {

	#fixme: bootmode can get from uboot.
	#bootconfig=`devmem 0x01073120`
	bootconfig=1
	mask=0x7

	let bootmode=$(($bootconfig & $mask))

	case $bootmode in
	0)
		flashtype=nor
		;;
	1)
		flashtype=nand
		;;
	4)
		#if bootmod is emmc, wait and check emmc partition
		echo "waiting emmc or sd device done"
		flashtype=mmc0
		;;
	*)
		echo "bootmode is not support now, bootmode = $bootmode"
		;;
	esac
}

# diff cpu
grep "hisilicon" /sys/firmware/devicetree/base/compatible
if [ $? == 0 ]; then
	get_flashtype
else
	get_flashtype
fi

#call function to get flashtype

#call function to get mtd_parts
#fixme: get mmc block from system information
get_parts

echo factory_part=$factory_part
echo usr_data_part=$usr_data_part

/etc/init.d/factory_mount.sh $flashtype $factory_part
/etc/init.d/usrdata_mount.sh $flashtype $usr_data_part
