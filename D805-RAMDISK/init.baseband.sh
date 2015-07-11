#!/sbin/busybox sh
#
#  SET BASEBAND VERSION FOR
#  UNOFFICIAL LP G2 DEVICES
#

# grep the modem partition for baseband version and set it
setprop ro.lge.basebandversion `strings /firmware/image/modem.b21 | grep "^M8974A-" | head -1`