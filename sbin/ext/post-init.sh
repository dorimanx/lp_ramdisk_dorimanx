#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.

BB=/sbin/busybox

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

OPEN_RW()
{
	$BB mount -o remount,rw /;
	$BB mount -o remount,rw /system;
}
OPEN_RW;

# run ROM scripts
$BB sh /init.qcom.post_boot.sh;

# clean old modules from /system and add new from ramdisk
if [ ! -d /system/lib/modules ]; then
        $BB mkdir /system/lib/modules;
fi;
cd /lib/modules/;
for i in *.ko; do
        $BB rm -f /system/lib/modules/"$i";
done;
cd /;

$BB chmod 755 /lib/modules/*.ko;
$BB cp -a /lib/modules/*.ko /system/lib/modules/;

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chown -R root:root /lib;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod 06755 /sbin/busybox
}
CRITICAL_PERM_FIX;

# make sure we own the device nodes
$BB chown system /sys/devices/system/cpu/cpufreq/ondemand/*
$BB chown system /sys/devices/system/cpu/cpu0/cpufreq/*
$BB chown system /sys/devices/system/cpu/cpu1/online
$BB chown system /sys/devices/system/cpu/cpu2/online
$BB chown system /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/stats/*
$BB chmod 666 /sys/devices/system/cpu/cpu1/online
$BB chmod 666 /sys/devices/system/cpu/cpu2/online
$BB chmod 666 /sys/devices/system/cpu/cpu3/online

# Fix ROM dev wrong sets.
setprop persist.adb.notify 0

if [ ! -d /data/.dori ]; then
	$BB mkdir /data/.dori/;
fi;

# reset profiles auto trigger to be used by kernel ADMIN, in case of need, if new value added in default profiles
# just set numer $RESET_MAGIC + 1 and profiles will be reset one time on next boot with new kernel.
# incase that ADMIN feel that something wrong with global STweaks config and profiles, then ADMIN can add +1 to CLEAN_DORI_DIR
# to clean all files on first boot from /data/.dori/ folder.
RESET_MAGIC=1;
CLEAN_DORI_DIR=1;

if [ ! -e /data/.dori/reset_profiles ]; then
	echo "$RESET_MAGIC" > /data/.dori/reset_profiles;
fi;
if [ ! -e /data/reset_dori_dir ]; then
	echo "$CLEAN_DORI_DIR" > /data/reset_dori_dir;
fi;
if [ -e /data/.dori/.active.profile ]; then
	PROFILE=$(cat /data/.dori/.active.profile);
else
	echo "default" > /data/.dori/.active.profile;
	PROFILE=$(cat /data/.dori/.active.profile);
fi;
if [ "$(cat /data/reset_dori_dir)" -eq "$CLEAN_DORI_DIR" ]; then
	if [ "$(cat /data/.dori/reset_profiles)" != "$RESET_MAGIC" ]; then
		if [ ! -e /data/.dori_old ]; then
			mkdir /data/.dori_old;
		fi;
		cp -a /data/.dori/*.profile /data/.dori_old/;
		$BB rm -f /data/.dori/*.profile;
		if [ -e /data/data/com.af.synapse/databases ]; then
			$BB rm -R /data/data/com.af.synapse/databases;
		fi;
		echo "$RESET_MAGIC" > /data/.dori/reset_profiles;
	else
		echo "no need to reset profiles or delete .dori folder";
	fi;
else
	# Clean /data/.dori/ folder from all files to fix any mess but do it in smart way.
	if [ -e /data/.dori/"$PROFILE".profile ]; then
		cp /data/.dori/"$PROFILE".profile /sdcard/"$PROFILE".profile_backup;
	fi;
	if [ ! -e /data/.dori_old ]; then
		mkdir /data/.dori_old;
	fi;
	cp -a /data/.dori/* /data/.dori_old/;
	$BB rm -f /data/.dori/*
	if [ -e /data/data/com.af.synapse/databases ]; then
		$BB rm -R /data/data/com.af.synapse/databases;
	fi;
	echo "$CLEAN_DORI_DIR" > /data/reset_dori_dir;
	echo "$RESET_MAGIC" > /data/.dori/reset_profiles;
	echo "$PROFILE" > /data/.dori/.active.profile;
fi;

[ ! -f /data/.dori/default.profile ] && cp -a /res/customconfig/default.profile /data/.dori/default.profile;
[ ! -f /data/.dori/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.dori/battery.profile;
[ ! -f /data/.dori/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.dori/performance.profile;
[ ! -f /data/.dori/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.dori/extreme_performance.profile;
[ ! -f /data/.dori/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.dori/extreme_battery.profile;

$BB chmod -R 0777 /data/.dori/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

# Load parameters for Synapse
DEBUG=/data/.dori/;
PVS=$(dmesg | grep "ACPU PVS" | cut -c34-45 | grep -v "REV");
echo "$PVS" > $DEBUG/acpu_pvs;
SPEED=$(dmesg | grep "SPEED BIN" | cut -c34-46);
echo "$SPEED" > $DEBUG/speed_bin;
BUSYBOX_VER=$(busybox | grep "BusyBox v" | cut -c0-15);
echo "$BUSYBOX_VER" > $DEBUG/busybox_ver;

######################################
# Loading Modules
######################################
MODULES_LOAD()
{
	# order of modules load is important

	if [ "$cifs_module" == "on" ]; then
		if [ -e /system/lib/modules/cifs.ko ]; then
			$BB insmod /system/lib/modules/cifs.ko;
		else
			$BB insmod /lib/modules/cifs.ko;
		fi;
	else
		echo "no user modules loaded";
	fi;
}

# enable kmem interface for everyone by GM
echo "0" > /proc/sys/kernel/kptr_restrict;

# disable debugging on some modules
if [ "$logger" -ge "1" ]; then
	echo "N" > /sys/module/kernel/parameters/initcall_debug;
#	echo "0" > /sys/module/alarm/parameters/debug_mask;
#	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
#	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
#	echo "0" > /sys/kernel/debug/clk/debug_suspend;
#	echo "0" > /sys/kernel/debug/msm_vidc/debug_level;
#	echo "0" > /sys/module/ipc_router/parameters/debug_mask;
#	echo "0" > /sys/module/msm_serial_hs/parameters/debug_mask;
#	echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask;
#	echo "0" > /sys/module/mpm_of/parameters/debug_mask;
#	echo "0" > /sys/module/msm_pm/parameters/debug_mask;
#	echo "0" > /sys/module/smp2p/parameters/debug_mask;
fi;

OPEN_RW;

# Start any init.d scripts that may be present in the rom or added by the user
$BB chmod 755 /system/etc/init.d/*;
if [ "$init_d" == "on" ]; then
	(
		$BB nohup $BB run-parts /system/etc/init.d/ > /data/.dori/init.d.txt &
	)&
else
	if [ -e /system/etc/init.d/99SuperSUDaemon ]; then
		$BB nohup $BB sh /system/etc/init.d/99SuperSUDaemon > /data/.dori/root.txt &
	else
		echo "no root script in init.d";
	fi;
fi;

# Fix critical perms again after init.d mess
CRITICAL_PERM_FIX;

if [ "$stweaks_boot_control" == "yes" ]; then
	# Load Custom Modules
	MODULES_LOAD;
fi;

# script finish here, so let me know when
TIME_NOW=$(date)
echo "$TIME_NOW" > /data/boot_log_dm

$BB mount -o remount,ro /system;

