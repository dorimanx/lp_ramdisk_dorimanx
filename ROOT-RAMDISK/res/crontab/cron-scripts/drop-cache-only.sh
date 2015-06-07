#!/sbin/busybox sh

(
	PROFILE=$(cat /data/.dori/.active.profile);
	. /data/.dori/${PROFILE}.profile;

	if [ "$cron_drop_cache" == "on" ]; then

		MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
		MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
		MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

		# do clean cache only if cache uses 50% of free memory.
		if [ "$MEM_USED_CALC" -gt "50" ]; then
			sync;
			sync;
			sysctl -w vm.drop_caches=3;
			date +%H:%M-%D-%Z > /data/crontab/cron-clear-ram-cache;
			echo "Cache above 50%! Cleaned RAM Cache" >> /data/crontab/cron-clear-ram-cache;
		fi;
	fi;
)&
