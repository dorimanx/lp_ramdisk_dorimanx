#!/sbin/busybox sh

BB=/sbin/busybox

cd /;

# copy cron files
$BB cp -a /res/crontab/ /data/
if [ ! -e /data/crontab/custom_jobs ]; then
	$BB touch /data/crontab/custom_jobs;
	$BB chmod 777 /data/crontab/custom_jobs;
fi;

STWEAKS_CHECK=$($BB find /data/app/ -name com.gokhanmoral.stweaks* | wc -l);

if [ "$STWEAKS_CHECK" -eq "1" ]; then
	$BB rm -f /data/app/com.gokhanmoral.stweaks* > /dev/null 2>&1;
	$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
fi;

if [ -f /system/priv-app/STweak*.apk ]; then
	$BB rm /system/priv-app/STweak*.apk;
fi;

if [ -f /system/app/STweaks.apk ]; then
	stmd5sum=$($BB md5sum /system/app/STweaks.apk | $BB awk '{print $1}');
	stmd5sum_kernel=$($BB cat /res/stweaks_md5);
	if [ "$stmd5sum" != "$stmd5sum_kernel" ]; then
		$BB rm -f /system/app/STweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
		$BB cp /res/misc/payload/STweaks.apk /system/app/;
		$BB chown root.root /system/app/STweaks.apk;
		$BB chmod 644 /system/app/STweaks.apk;
	fi;
else
	$BB rm -r /data/data/com.gokhanmoral.*weak*/* > /dev/null 2>&1;
	$BB cp -a /res/misc/payload/STweaks.apk /system/app/;
	$BB chown root.root /system/app/STweaks.apk;
	$BB chmod 644 /system/app/STweaks.apk;
fi;
