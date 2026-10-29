#!/bin/sh

########################################################################
#==============this is a demo, do whatever you want to=================#
########################################################################

# add some ota-related applications here, such an ota server application.
# attentions: copy the applications to /tmp before running it.
# example:
# cp /local/usr/bin/foo /tmp
# /tmp/foo

# flagfile, can restore any information you want, such as image filename,
# so you can use artosyn_upgrade upgrade automatically

#flagfile=$1

# tmp rootfs dir, is common for emmc, nor, nand
rtfs_dir="/tmp"

cp -r /factory/* $rtfs_dir/
chmod 777 /tmp/*

#start fpv upgrade
if [ -e "/etc/init.d/start_clean_system_fpv_upgrade.sh" ]; then
	. /etc/init.d/start_clean_system_fpv_upgrade.sh
fi
