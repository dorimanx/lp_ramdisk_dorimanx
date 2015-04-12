#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

# Cleanup the old busybox symlinks
cd /system/xbin/;
SBIN_BUSYBOX=$($BB ls -ltra | grep '\-> /sbin/busybox' | sed 's/->//' | sed 's/.sbin//' | sed 's/.busybox//' | cut -c 58-70 | wc -l);
SYSTEM_BUSYBOX=$($BB ls -ltra | grep '\-> /system/xbin/busybox' | sed 's/->//' | sed 's/.system//' | sed 's/.xbin//' | sed 's/.busybox//' | cut -c 58-70 | wc -l);

if [ "$SBIN_BUSYBOX" -ge "1" ]; then
	for i in "$($BB ls -ltra | grep '\-> /sbin/busybox' | sed 's/->//' | sed 's/.sbin//' | sed 's/.busybox//' | cut -c 58-70)"; do
	rm $i;
	done;
fi;

if [ "$SYSTEM_BUSYBOX" -ge "1" ]; then
	for i in "$($BB ls -ltra | grep '\-> /system/xbin/busybox' | sed 's/->//' | sed 's/.system//' | sed 's/.xbin//' | sed 's/.busybox//' | cut -c 58-70)"; do
	rm $i;
	done;
fi;
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

