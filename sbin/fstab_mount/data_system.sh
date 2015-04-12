#!/sbin/busybox sh

BB=/sbin/busybox

SYSTEM=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/system | $BB grep "f2fs" | $BB wc -l);
DATA=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/userdata | $BB grep "f2fs" | $BB wc -l);

SYSTEM_TYPE=0;
DATA_TYPE=0;

if [ "$SYSTEM" -eq "1" ]; then
	SYSTEM_TYPE=1;
fi;
if [ "$DATA" -eq "1" ]; then
	DATA_TYPE=1;
fi;

$BB mount -o remount,rw /;

if [ "$SYSTEM_TYPE" -eq "1" ] && [ "$DATA_TYPE" -eq "1" ]; then
	$BB cp -p /sbin/fstab_mount/fstab_f2fs_system_data.g2 /fstab.g2;
elif [ "$SYSTEM_TYPE" -eq "1" ] && [ "$DATA_TYPE" -eq "0" ]; then
	$BB cp -p /sbin/fstab_mount/fstab_f2fs_system.g2 /fstab.g2;
elif [ "$SYSTEM_TYPE" -eq "0" ] && [ "$DATA_TYPE" -eq "1" ]; then
	$BB cp -p /sbin/fstab_mount/fstab_f2fs_data.g2 /fstab.g2;
fi;

