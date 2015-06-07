#!/sbin/busybox sh
# Clear Cache script

(
	PROFILE=$(cat /data/.dori/.active.profile);
	. /data/.dori/${PROFILE}.profile;

	if [ "$cron_clear_app_cache" == "on" ]; then
		CACHE_JUNK=$(ls -d /data/data/*/cache)
		for i in $CACHE_JUNK; do
			rm -rf $i/*
		done;

		# Old logs
		rm -f /data/tombstones/*;
		rm -f /data/anr/*;
		rm -f /data/system/dropbox/*;
		date +%H:%M-%D-%Z > /data/crontab/cron-clear-file-cache;
		echo "Done! Cleaned Apps Cache" >> /data/crontab/cron-clear-file-cache;
		sync;
	fi;
)&
