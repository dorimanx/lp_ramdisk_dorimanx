#!/sbin/busybox sh

BB=/sbin/busybox

if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

CLEAN_BUSYBOX()
{
	for f in *; do
		case "$($BB readlink "$f")" in *usybox*)
			$BB rm "$f"
		;;
		esac
	done;
}

# Cleanup the old busybox symlinks
cd /system/xbin/;
CLEAN_BUSYBOX;

cd /system/bin/;
CLEAN_BUSYBOX;

cd /;

# Install latest busybox to ROM
$BB cp /sbin/busybox /system/xbin/;

/system/xbin/busybox --install -s /system/xbin/
if [ -e /system/xbin/wget ]; then
	rm /system/xbin/wget;
fi;
if [ -e /system/wget/wget ]; then
	chmod 755 /system/wget/wget;
	ln -s /system/wget/wget /system/xbin/wget;
fi;
chmod 06755 /system/xbin/busybox;
if [ -e /system/xbin/su ]; then
	$BB chmod 06755 /system/xbin/su;
fi;
if [ -e /system/xbin/daemonsu ]; then
	$BB chmod 06755 /system/xbin/daemonsu;
fi;

$BB sh /sbin/ext/post-init.sh;

