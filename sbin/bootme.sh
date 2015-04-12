#!/sbin/busybox sh

input keyevent 26
sync
sync
stop
/sbin/busybox mount -o remount,ro /system;
echo "rebooting to recovery now"
sleep 3;
reboot recovery

