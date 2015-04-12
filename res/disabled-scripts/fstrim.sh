#!/sbin/busybox sh

(
	BB=/sbin/busybox
	PROFILE=$(cat /data/.dori/.active.profile);
	. /data/.dori/${PROFILE}.profile;

	if [ "$cron_fstrim" == "on" ]; then
		SCREEN_WAS_OFF=0;
		SYSTEM_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/system | $BB grep "f2fs" | $BB wc -l)
		DATA_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/data | $BB grep "f2fs" | $BB wc -l)
		CACHE_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/cache | $BB grep "f2fs" | $BB wc -l)

		if [ "$SYSTEM_CHECK" -eq "0" ] || [ "$DATA_CHECK" -eq "0" ] || [ "$CACHE_CHECK" -eq "0" ]; then
			if [ "$(dumpsys power | grep mScreenOn= | grep -oE '(true|false)')" == false ] ; then
				input keyevent 26 # wakeup
				SCREEN_WAS_OFF=1;
			fi;
		fi;

		if [ "$SYSTEM_CHECK" -eq "0" ]; then
			$BB fstrim /system
		fi;
		if [ "$DATA_CHECK" -eq "0" ]; then
			$BB fstrim /data
		fi;
		if [ "$CACHE_CHECK" -eq "0" ]; then
			$BB fstrim /cache
		fi;
		date +%H:%M-%D-%Z > /data/crontab/cron-fstrim;
		echo "FS Trimmed" >> /data/crontab/cron-fstrim;
		sync;
		if [ "$SCREEN_WAS_OFF" -eq "1" ]; then
			input keyevent 26 # sleep
		fi;
	fi;
)&
