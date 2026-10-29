#!/bin/sh
# Dev root on GT Pro: password in /usrdata, stock rootfs not permanently modified.
# Called from fpv_run_* on each boot AND from end of patched config_serial.sh
# (covers clean-system boot mode, where fpv_run never runs).
#
# v3: no RNDIS experiments. Shell channel = second ACM (ttyGS1) with getty,
# spawned by patched config_serial.sh after gadget bind.

DEV=/usrdata/fpv/dev
DISABLE="$DEV/DISABLE_ROOT_HOOK"
SHADOW="$DEV/shadow"
HASH='$6$AscentSalt$pQXXb6ls5xVZbj5RKFG8JQUJj012lK58TaE0MmzesHDFyw2v.t5PN2Aek4mOS03PosuHYPh20hUmUE/3UgIfd1'

[ -f "$DISABLE" ] && exit 0

mkdir -p "$DEV"
echo "root:${HASH}:1:0:99999:7:::" > "$SHADOW"
chmod 0600 "$SHADOW"

# Prefer bind-mount (same idea as fpvOS air/start.sh): no remount,rw on /.
if ! grep -q ' /etc/shadow ' /proc/mounts 2>/dev/null; then
	if mount --bind "$SHADOW" /etc/shadow 2>/dev/null; then
		: # ok
	else
		# Early boot or old kernel: last-resort direct write (legacy path).
		mount -o remount,rw / 2>/dev/null
		cp "$SHADOW" /etc/shadow
		sync
	fi
fi

killall telnetd 2>/dev/null
telnetd
