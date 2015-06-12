#!/sbin/busybox sh

mount -o remount,rw /system
restorecon -RF /system

if [ -e /system/bin/app_process32_xposed ]; then
        chcon u:object_r:zygote_exec:s0 /system/bin/app_process32_xposed
fi;

mount -o remount,ro /system
