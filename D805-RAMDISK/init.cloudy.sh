#!/sbin/busybox sh
#
#  Cloudyfa's RILD fix
#

mount -o rw,remount /system
mkdir -p /system/lib/temp

cp /system/lib/libvss_common_core.so /system/lib/temp/libdummy.so
for i in {1..9}; do
	sleep 2
	cp /system/lib/temp/libdummy.so /system/lib/libvss_common_core.so
done
for i in {1..3}; do
	sleep 8
	cp /system/lib/temp/libdummy.so /system/lib/libvss_common_core.so
done

rm -rf /system/lib/temp
mount -o ro,remount /system
