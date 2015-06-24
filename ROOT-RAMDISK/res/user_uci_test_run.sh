#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
BB=/sbin/busybox

if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | grep system | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

chown -R root:system /res/customconfig/actions/;
chmod -R 06755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 06755 /res/no-push-on-boot/*;
/sbin/busybox cp /res/misc_scripts/config_backup_restore /res/customconfig/actions/push-actions/;
chmod 06755 /res/customconfig/actions/push-actions/config_backup_restore;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
apply_config;
write_config;

# restore all the PUSH Button Actions back to there location
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";

/sbin/busybox mount -o remount,ro /system;

