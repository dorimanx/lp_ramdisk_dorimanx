#!/sbin/busybox sh

(
	PROFILE=$(cat /data/.dori/.active.profile);
	. /data/.dori/${PROFILE}.profile;

	if [ "$reset_battery" == "on" ]; then
		echo "reset" > /sys/bus/i2c/devices/1-0036/fuelrst;
		date +%H:%M-%D-%Z > /data/crontab/cron-reset_battery;
		echo "Battery Reset" >> /data/crontab/cron-reset_battery;
	fi;
)&
