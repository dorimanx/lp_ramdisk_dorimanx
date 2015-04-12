#!/sbin/busybox sh

BB=/sbin/busybox

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

cd /;

if [ -e /system/app/SuperSU.apk ] && [ -e /system/xbin/daemonsu ]; then
	if [ -e /system/chainfire/SuperSU.apk ]; then
		sumd5sum=$($BB md5sum /system/app/SuperSU.apk | $BB awk '{print $1}');
	else
		sumd5sum=1;
	fi;
	if [ -e /system/chainfire/SuperSU.apk.md5 ]; then
		sumd5sum_kernel=$($BB cat /system/chainfire/SuperSU.apk.md5);
	else
		sumd5sum_kernel=1;
	fi;
	if [ "$sumd5sum" == "$sumd5sum_kernel" ]; then
		NEW_SU=0;
	else
		NEW_SU=1;
	fi;
else
	NEW_SU=1;
fi;

if [ "$install_root" == "on" ]; then
	if [ "$NEW_SU" -eq "0" ]; then
		echo "SuperSU already exists";
		$BB chmod 06755 /system/xbin/su;
		if [ -e /system/xbin/daemonsu ]; then
			$BB chmod 06755 /system/xbin/daemonsu;
		fi;
	else
		echo "ROOT NOT detected, Installing SuperSU";
		# clean su traces
		$BB rm -f /system/bin/su > /dev/null 2>&1;
		$BB rm -f /system/xbin/su > /dev/null 2>&1;
		if [ ! -d /system/bin/.ext ]; then
			$BB mkdir /system/bin/.ext;
			$BB chmod 777 /system/bin/.ext;
		else
			$BB rm -f /system/bin/.ext/* > /dev/null 2>&1;
		fi;

		# clean super user old apps
		$BB rm -f /system/app/*uper?ser.apk > /dev/null 2>&1;
		$BB rm -f /system/app/?uper?u.apk > /dev/null 2>&1;
		$BB rm -f /system/app/*chainfire?supersu.apk > /dev/null 2>&1;
		$BB rm -f /data/app/*uper?ser.apk > /dev/null 2>&1;
		$BB rm -f /data/app/?uper?u.apk > /dev/null 2>&1;
		$BB rm -f /data/app/*chainfire?supersu.apk > /dev/null 2>&1;

		if [ -e /system/chainfire/SuperSU.apk ]; then
			$BB cp /system/chainfire/SuperSU.apk /system/app/;
			$BB cp /system/chainfire/SuperSUNoNag-v1.00.apk /system/app/;
			$BB cp /system/chainfire/xbin/access /system/xbin/su;
			$BB cp /system/chainfire/xbin/access /system/xbin/daemonsu;
			$BB cp /system/xbin/su /system/bin/.ext/;

			if [ ! -e /system/xbin/chattr ]; then
				$BB cp /system/chainfire/xbin/chattr /system/xbin/;
				$BB chmod 06755 /system/xbin/chattr;
			fi;
			$BB chmod 06755 /system/xbin/su;
			$BB chmod 06755 /system/xbin/daemonsu;
			$BB chmod 06755 /system/xbin/.ext/su;
			$BB chmod 644 /system/app/SuperSU.apk;
			$BB chmod 644 /system/app/SuperSUNoNag-v1.00.apk;
			$BB chown root.root /system/xbin/su;
			$BB chown root.root /system/xbin/daemonsu;
			$BB chown root.root /system/app/SuperSU.apk;
			$BB chown root.root /system/app/SuperSUNoNag-v1.00.apk;
		fi;

		if [ ! -e /data/app/*chainfire?supersu.pr*.apk ]; then
			if [ -e /data/system/chain_pro.apk_bkp ]; then
				$BB mv /data/system/chain_pro.apk_bkp /system/app/eu.chainfire.supersu.pro-1.apk;
				$BB chmod 644 /system/app/eu.chainfire.supersu.pro-1.apk;
			else
				echo "no su pro" > /dev/null 2>&1;
			fi;
		fi;

		# kill superuser pid
		$BB pkill -f "com.noshufou.android.su";
		$BB pkill -f "eu.chainfire.supersu";
	fi;
fi;

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;
