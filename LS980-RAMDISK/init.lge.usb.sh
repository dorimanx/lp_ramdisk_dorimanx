#!/system/bin/sh
# Copyright (c) 2012, Code Aurora Forum. All rights reserved.
# Copyright (c) 2012, LG Electronics Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of Code Aurora Forum, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
chown -h root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod -h 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

#
# Allow persistent usb charging disabling
# User needs to set usb charging disabled in persist.usb.chgdisabled
#
target=`getprop ro.board.platform`
usbchgdisabled=`getprop persist.usb.chgdisabled`
case "$usbchgdisabled" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8660")
        echo "$usbchgdisabled" > /sys/module/pmic8058_charger/parameters/disabled
        echo "$usbchgdisabled" > /sys/module/smb137b/parameters/disabled
    ;;
        "msm8960")
        echo "$usbchgdisabled" > /sys/module/pm8921_charger/parameters/disabled
    ;;
        "msm8994" | "msm8992")
        echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
        echo 1 > /sys/class/android_usb/android0/f_rndis_qc/max_pkt_per_xfer # Disable RNDIS UL aggregation
        echo qti,bam2bam_ipa > /sys/class/android_usb/android0/f_rmnet/transports
    ;;
        "apq8084")
        echo qti,ether > /sys/class/android_usb/android0/f_rmnet/transports
    ;;
        "apq8064")
        echo hsic,hsic > /sys/class/android_usb/android0/f_rmnet/transports
    ;;
        * )
        echo smd,bam > /sys/class/android_usb/android0/f_rmnet/transports
    ;;
    esac
esac

echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
echo 1  > /sys/class/android_usb/f_cdrom_storage/lun/nofua

#
# Allow USB enumeration with default PID/VID
#
usb_config=`getprop persist.sys.usb.config`
case "$usb_config" in
        "") #USB persist config not set, select default configuration
        setprop persist.sys.usb.config mtp_only
        ;;
        "adb")
        setprop persist.sys.usb.config mtp_only,adb
        ;;
        * ) ;; #USB persist config exists, do nothing
esac
