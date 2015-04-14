#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`
battery_present=`cat /sys/class/power_supply/battery/present`
case "$target" in
    "msm8974")
	# we must never touch this. it's should be 4 "power collapse = PC".
        echo 4 > /sys/module/lpm_levels/enable_low_power/l2
	# we must set here 1 for core0 too, or it's not enter suspend, and waste power.
        echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/suspend_enabled
	# enable full suspend for all non boot cores.
        echo 1 > /sys/module/msm_pm/modes/cpu1/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu2/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu3/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/idle_enabled
	# retention should be OFF.
        echo 0 > /sys/module/msm_pm/modes/cpu0/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu1/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu2/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu3/retention/idle_enabled
        echo 0 > /sys/module/msm_thermal/core_control/enabled
        if [ "$battery_present" -eq "1" ]; then
            echo 1 > /sys/devices/system/cpu/cpu1/online
            echo 1 > /sys/devices/system/cpu/cpu2/online
            echo 1 > /sys/devices/system/cpu/cpu3/online
        else
            echo 0 > /sys/devices/system/cpu/cpu1/online
            echo 0 > /sys/devices/system/cpu/cpu2/online
            echo 0 > /sys/devices/system/cpu/cpu3/online
        fi
        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi

        if [ -f /sys/devices/f9967000.i2c/i2c-0/0-0072/enable_irq ]; then
                echo 1 > /sys/devices/f9967000.i2c/i2c-0/0-0072/enable_irq
        else
                echo "doesn't find slimport enable_irq"
        fi

        case "$soc_id" in
            "208" | "211" | "214" | "217" | "209" | "212" | "215" | "218" | "194" | "210" | "213" | "216")
                for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
                do
                    echo "cpubw_hwmon" > $devfreq_gov
                done
                echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
                echo 90 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
                echo 1190400 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
                echo 1 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
                echo 40000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
                echo 20 > /sys/module/cpu_boost/parameters/boost_ms
                echo 1497600 > /sys/module/cpu_boost/parameters/input_boost_freq
                echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

                #Set LGE Interactive-Grid parameters for G3 models
                echo "20000 1100000:40000 1500000:20000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
                echo "85 1500000:90" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
                echo 960000 > /sys/module/cpu_boost/parameters/sync_threshold
                echo 0 > /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor

                echo 1 > /sys/devices/system/cpu/cpufreq/interactive/is_grid
                echo 40000 > /sys/devices/system/cpu/cpufreq/interactive/above_optimal_max_freq_delay
                echo 960000 > /sys/devices/system/cpu/cpufreq/interactive/optimal_max_freq
                echo 7 > /sys/devices/system/cpu/cpufreq/interactive/middle_grid_step
                echo 37 > /sys/devices/system/cpu/cpufreq/interactive/middle_grid_load
                echo 14 > /sys/devices/system/cpu/cpufreq/interactive/high_grid_step
                echo 46 > /sys/devices/system/cpu/cpufreq/interactive/high_grid_load
                echo 1000 > /sys/class/devfreq/g3-display.0/polling_interval

                setprop ro.qualcomm.perf.cores_online 2
            ;;
            *)
                echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
                echo "ondemand" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
                echo "ondemand" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
                echo "ondemand" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
                echo 50000 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
                echo 90 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
                echo 1 > /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
                echo 2 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
                echo 10 > /sys/devices/system/cpu/cpufreq/ondemand/down_differential
                echo 70 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_multi_core
                echo 3 > /sys/devices/system/cpu/cpufreq/ondemand/down_differential_multi_core
                echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/optimal_freq
                echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/sync_freq
                echo 80 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_any_cpu_load

                #Set LGE Ondemand-Grid parameters for msm8974aa
                echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/optimal_max_freq
                echo 7 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_step
                echo 40 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_load
                echo 14 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_step
                echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_load
            ;;
        esac
        echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        echo 300000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
        echo 300000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
        echo 300000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
        chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
        chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        echo 1 > /sys/module/msm_thermal/core_control/enabled
	if [ -e /sys/devices/system/cpu/mfreq ]; then
        	chown root.system /sys/devices/system/cpu/mfreq
        	chmod 220 /sys/devices/system/cpu/mfreq
	fi;
        chown root.system /sys/devices/system/cpu/cpu1/online
        chown root.system /sys/devices/system/cpu/cpu2/online
        chown root.system /sys/devices/system/cpu/cpu3/online
        chmod 664 /sys/devices/system/cpu/cpu1/online
        chmod 664 /sys/devices/system/cpu/cpu2/online
        chmod 664 /sys/devices/system/cpu/cpu3/online
        echo 1 > /dev/cpuctl/apps/cpu.notify_on_migrate
    ;;
esac


chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot" in
    "true")
	if [ -d /sys/devices/platform/rs300000a7.65536 ]; then
        	chown system /sys/devices/platform/rs300000a7.65536/force_sync
        	chown system /sys/devices/platform/rs300000a7.65536/sync_sts
        	chown system /sys/devices/platform/rs300100a7.65536/force_sync
        	chown system /sys/devices/platform/rs300100a7.65536/sync_sts
	fi;
    ;;
esac

# Post-setup services
if [ "$battery_present" -eq "1" ]; then
	start mpdecision
fi
echo 1024 > /sys/block/mmcblk0/bdi/read_ahead_kb

# Install AdrenoTest.apk if not already installed
if [ -f /data/prebuilt/AdrenoTest.apk ]; then
    if [ ! -d /data/data/com.qualcomm.adrenotest ]; then
        pm install /data/prebuilt/AdrenoTest.apk
    fi
fi

# Install SWE_Browser.apk if not already installed
if [ -f /data/prebuilt/SWE_AndroidBrowser.apk ]; then
    if [ ! -d /data/data/com.android.swe.browser ]; then
        pm install /data/prebuilt/SWE_AndroidBrowser.apk
    fi
fi

case "$target" in
    "msm8226" | "msm8974" | "msm8610" | "apq8084" | "mpq8092" | "msm8610")
        # Let kernel know our image version/variant/crm_version
        image_version="10:"
        image_version_1=`getprop ro.build.id`
        image_version_2=":"
        image_version_3=`getprop ro.build.version.incremental`

        image_variant=`getprop ro.product.name`
        image_variant_1="-"
        image_variant_2=`getprop ro.build.type`
        oem_version=`getprop ro.build.version.codename`
        echo 10 > /sys/devices/soc0/select_image
        echo "$image_version$image_version_1$image_version_2$image_version_3" > /sys/devices/soc0/image_version
        echo "$image_variant$image_variant_1$image_variant_2" > /sys/devices/soc0/image_variant
        echo $oem_version > /sys/devices/soc0/image_crm_version
        ;;
esac

# 2013-10-07 ct-radio@lge.com LGP_DATA_TCPIP_NSRM [START]
targetProd=`getprop ro.product.name`
case "$targetProd" in
		"g2_lgu_kr" | "b1_lgu_kr")
						mkdir /data/connectivity/
						chown system.system /data/connectivity/
						chmod 775 /data/connectivity/
						mkdir /data/connectivity/nsrm/
						chown system.system /data/connectivity/nsrm/
						chmod 775 /data/connectivity/nsrm/
						cp /system/etc/dpm/nsrm/NsrmConfiguration.xml /data/connectivity/nsrm/
						chown system.system /data/connectivity/nsrm/NsrmConfiguration.xml
						chmod 775 /data/connectivity/nsrm/NsrmConfiguration.xml
			;;
esac
# 2013-10-07 ct-radio@lge.com LGP_DATA_TCPIP_NSRM [END]
