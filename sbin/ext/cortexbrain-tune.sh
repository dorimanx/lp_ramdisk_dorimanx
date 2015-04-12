#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

BB=/sbin/busybox

# change mode for /tmp/
ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	mount -o remount,rw /;
fi;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
# (since we don't have the recovery source code I can't change the ".dori" dir, so just leave it there for history)
DATA_DIR=/data/.dori;

# ==============================================================
# INITIATE
# ==============================================================

# For CHARGER CHECK.
echo "1" > /data/dori_cortex_sleep;

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local i="";

		local MMC=$(find /sys/block/mmc*);
		for i in $MMC; do
			echo "$scheduler" > "$i"/queue/scheduler;
			echo "0" > "$i"/queue/rotational;
			echo "0" > "$i"/queue/iostats;
			echo "1" > "$i"/queue/rq_affinity;
		done;

		# This controls how many requests may be allocated
		# in the block layer for read or write requests.
		# Note that the total allocated number may be twice
		# this amount, since it applies only to reads or writes
		# (not the accumulated sum).
		echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

		# our storage is 16/32GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "$read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;
		echo "$read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t "$FILE_NAME" "*** IO_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == "on" ]; then
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;

		log -p i -t "$FILE_NAME" "*** KERNEL_TWEAKS ***: enabled";
	else
		echo "kernel_tweaks disabled";
	fi;
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "32 32" > /proc/sys/vm/lowmem_reserve_ratio;

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";
	else
		echo "memory_tweaks disabled";
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == "on" ]; then
		setprop windowsmgr.max_events_per_sec 240;

		log -p i -t "$FILE_NAME" "*** SYSTEM_TWEAKS ***: enabled";
	else
		echo "system_tweaks disabled";
	fi;
}
SYSTEM_TWEAKS;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 10
		echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 20
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "4096" > /proc/sys/vm/min_free_kbytes;

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
MEMORY_TWEAKS;

# if crond used, then give it root perent - if started by STweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == "on" ]; then
		if [ "$(pgrep -f crond | wc -l)" -eq "0" ]; then
			$BB sh /res/crontab_service/service.sh > /dev/null;
			log -p i -t "$FILE_NAME" "*** CROND STARTED ***";
		else
			log -p i -t "$FILE_NAME" "*** CROND IS ONLINE ***";
		fi;
	else
		log -p i -t "$FILE_NAME" "*** CROND IS OFFLINE ***";
	fi;
}

IO_SCHEDULER()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local state="$1";
		local sys_mmc0_scheduler_tmp="/sys/block/mmcblk0/queue/scheduler";
		local new_scheduler="";
		local tmp_scheduler=$(cat "$sys_mmc0_scheduler_tmp" | sed -n 's/^.*\[\([a-z|A-Z]*\)\].*/\1/p');

		if [ ! -e "$sys_mmc1_scheduler_tmp" ]; then
			sys_mmc1_scheduler_tmp="/dev/null";
		fi;

		if [ "$state" == "awake" ]; then
			new_scheduler="$scheduler";
			if [ "$tmp_scheduler" != "$scheduler" ]; then
				echo "$scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		elif [ "$state" == "sleep" ]; then
			new_scheduler="$sleep_scheduler";
			if [ "$tmp_scheduler" != "$sleep_scheduler" ]; then
				echo "$sleep_scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		fi;

		log -p i -t "$FILE_NAME" "*** IO_SCHEDULER: $state - $new_scheduler ***: done";
	else
		log -p i -t "$FILE_NAME" "*** Cortex IO_SCHEDULER: Disabled ***";
	fi;
}

CPU_CENTRAL_CONTROL()
{
	GOV_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

	local state="$1";

	if [ "$cortexbrain_cpu" == "on" ]; then

		if [ "$state" == "awake" ]; then
			echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu1_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1;
			echo "$cpu2_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2;
			echo "$cpu3_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3;

                        echo "$cpu0_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
                        echo "$cpu1_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu1;
                        echo "$cpu2_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu2;
                        echo "$cpu3_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu3;
			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;
		elif [ "$state" == "sleep" ]; then
			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "729600" ]; then
				echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;
			if [ "$suspend_max_freq" -lt "2803200" ]; then
				echo "$suspend_max_freq" > /sys/kernel/msm_cpufreq_limit/suspend_max_freq;
			fi;
			if [ -e /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate ]; then
				if [ "$(cat /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate)" -lt "50000" ]; then
					echo "50000" > /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate;
				fi;
			fi;
		fi;
		log -p i -t "$FILE_NAME" "*** CPU_CENTRAL_CONTROL max_freq:${cpu_max_freq} min_freq:${cpu_min_freq}***: done";
	else
		if [ "$state" == "awake" ]; then
			echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu1_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1;
			echo "$cpu2_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2;
			echo "$cpu3_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3;
			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;
		elif [ "$state" == "sleep" ]; then
			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "729600" ]; then
				echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;
			if [ -e /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate ]; then
				if [ "$(cat /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate)" -lt "50000" ]; then
					echo "50000" > /sys/devices/system/cpu/cpufreq/$GOV_NAME/sampling_rate;
				fi;
			fi;
		fi;
	fi;
}

HOTPLUG_CONTROL()
{
	if [ "$(pgrep -f "/system/bin/thermal-engine" | wc -l)" -eq "1" ]; then
		$BB renice -n -20 -p "$(pgrep -f "/system/bin/thermal-engine")";
	fi;

	if [ "$hotplug" == "default" ]; then
		if [ -e /system/bin/mpdecision ]; then
			if [ "$(pgrep -f "/system/bin/mpdecision" | wc -l)" -eq "0" ]; then
				/system/bin/start mpdecision
				$BB renice -n -20 -p "$(pgrep -f "/system/bin/start mpdecision")";
			fi;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
			if [ -e /system/bin/mpdecision ]; then
				/system/bin/stop mpdecision
				/system/bin/start mpdecision
				$BB renice -n -20 -p "$(pgrep -f "/system/bin/start mpdecision")";
				echo "20" > /sys/devices/system/cpu/cpu0/rq-stats/run_queue_poll_ms;
			else
				# Some !Stupid APP! changed mpdecision name, not my problem. use msm hotplug!
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
				echo "1" > /sys/module/msm_hotplug/msm_enabled;
			fi;
		fi;
	elif [ "$hotplug" == "msm_hotplug" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "0" ]; then
			(
				sleep 2;
				echo "1" > /sys/module/msm_hotplug/msm_enabled;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	elif [ "$hotplug" == "intelli" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "0" ]; then
			(
				sleep 2;
				echo "1" > /sys/kernel/intelli_plug/intelli_plug_active;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	elif [ "$hotplug" == "alucard" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "0" ]; then
			(
				sleep 2;
				echo "1" > /sys/kernel/alucard_hotplug/hotplug_enable;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	fi;
}

WORKQUEUE_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		if [ "$power_efficient" == "on" ]; then
			echo "1" > /sys/module/workqueue/parameters/power_efficient;
		else
			echo "0" > /sys/module/workqueue/parameters/power_efficient;
		fi;
	elif [ "$state" == "sleep" ]; then
		echo "1" > /sys/module/workqueue/parameters/power_efficient;
	fi;
	log -p i -t "$FILE_NAME" "*** WORKQUEUE_CONTROL ***: done";
}

INCALL_SPEAKER()
{
	local TELE_DATA=$(dumpsys telephony.registry | awk '/mCallState/ {print $1}');

	local HEADPHONES_PLUG=$(dumpsys statusbar | grep headset | awk '/visible/ {print $6}');

	GAIN_CHECK=0;

	if [ "$generic_headphone_left" != "$incall_volume"]; then
		GAIN_CHECK=1;
	fi;

	if [ "$generic_headphone_right" != "$incall_volume" ]; then
		GAIN_CHECK=1;
	fi;

	if [ "$TELE_DATA" != "mCallState=0" ] && [ "$HEADPHONES_PLUG" == "visible=false" ] && [ "$GAIN_CHECK" -eq "1" ]; then
		local INCALL_VOL=$incall_volume;
		if [ "$INCALL_VOL" -lt "0" ]; then
			local INCALL_VOL=$(($INCALL_VOL + 256))
		fi;

		echo "$INCALL_VOL $INCALL_VOL" > /sys/kernel/sound_control_3/lge_headphone_gain;

		(
			if [ "$(cat /sys/power/autosleep)" == "off" ]; then
				sleep 10;
				local TELE_DATA=$(dumpsys telephony.registry | awk '/mCallState/ {print $1}');
				if [ "$TELE_DATA" == "mCallState=0" ]; then
					if [ "$GAIN_CHECK" -eq "1" ] && [ -e /res/uci.sh ]; then
						sh /res/uci.sh generic_headphone_left $generic_headphone_left;
						sh /res/uci.sh generic_headphone_right $generic_headphone_right;
						log -p i -t "$FILE_NAME" "*** HEAD_PHONES_GAIN: L $generic_headphone_left R $generic_headphone_right ***: done";
					else
						log -p i -t "$FILE_NAME" "*** HEAD_PHONES_GAIN: no change is needed ***: done";
					fi;
				fi;
			fi;
		)&

		log -p i -t "$FILE_NAME" "*** IN_CALL_GAIN: $INCALL_VOL ***: done";
	else
		if [ -e /res/uci.sh ] && [ "$GAIN_CHECK" -eq "1" ]; then
			sh /res/uci.sh generic_headphone_left $generic_headphone_left;
			sh /res/uci.sh generic_headphone_right $generic_headphone_right;
			log -p i -t "$FILE_NAME" "*** HEAD_PHONES_GAIN: L $generic_headphone_left R $generic_headphone_right ***: done";
		else
			log -p i -t "$FILE_NAME" "*** HEAD_PHONES_GAIN: no change is needed ***: done";
		fi;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	CPU_CENTRAL_CONTROL "awake";
	INCALL_SPEAKER;

	if [ "$(cat /data/dori_cortex_sleep)" -eq "1" ]; then
		IO_SCHEDULER "awake";
		HOTPLUG_CONTROL;
		WORKQUEUE_CONTROL "awake";
		echo "0" > /data/dori_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAKEUP ***: done";
	else
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAS NOT SLEEPING ***: done";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	CHARGER_STATE=$(cat /sys/class/power_supply/battery/charging_enabled);

	CROND_SAFETY;
	INCALL_SPEAKER;

	if [ "$CHARGER_STATE" -eq "0" ]; then
		IO_SCHEDULER "sleep";
		CPU_CENTRAL_CONTROL "sleep";
		WORKQUEUE_CONTROL "sleep";
		echo "1" > /data/dori_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** SLEEP mode ***";
	else
		echo "0" > /data/dori_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** NO SLEEP CHARGING ***";
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ "$(pgrep -f "/sbin/ext/cortexbrain-tune.sh" | wc -l)" -eq "2" ]; then
	(while true; do
		while [ "$(cat /sys/power/autosleep)" != "off" ]; do
			sleep "3";
		done;
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/power/autosleep)" != "mem" ]; do
			sleep "3";
		done;
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;
