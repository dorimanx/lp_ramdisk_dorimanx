echo [[[[ Preload Copy Started ]]]]

	if [ ! -e /data/media/0/Preload ]; then
		/system/bin/mkdir /data/media/0/Preload
		/system/bin/chown media_rw.media_rw /data/media/0/Preload
		/system/bin/chmod 775 /data/media/0/Preload

		ln -s /system/Preload/Europe_by_Dominic_FHD.dm /data/media/0/Preload/Europe_by_Dominic_FHD.dm
		ln -s /system/Preload/Norway_FHD_HEVC.dm /data/media/0/Preload/Norway_FHD_HEVC.dm
		ln -s /system/Preload/LG/01_Life_Is_Good.flac /data/media/0/Preload/01_Life_Is_Good.flac
		ln -s /system/Preload/LG/02_Heart_of_Jungle.flac /data/media/0/Preload/02_Heart_of_Jungle.flac
		ln -s /system/Preload/LG/03_Air_on_the_G_String.flac /data/media/0/Preload/03_Air_on_the_G_String.flac
	fi
echo [[[[ Preload Copy ended ]]]]
