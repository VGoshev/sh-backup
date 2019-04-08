#!/bin/sh

SPACE_CHARS="_"
EPREFIX="/home/sunx"

OUT_DIR="/home/backup/sunx/SunX/new"
SRC_LIST="/home/sunx"
EXCLUDE=" \
#Documents_and_other_non-config_directories \
	Documents tmp GOG Games bin \
	VirtualBox_VMs .VirtualBox \
	.local/share/JetBrains/Toolbox/apps \
	\
#Twister_dir_is_quite_sizeable,_wont_backup_it	\
	.twister \
#Different_Caches_and_logs \
	.xsession-errors \
	\
	.cache fontconfig .fontconfig .compose-cache \
	.thumbnails	.nv \
	.opera/opcache .opera/cache \
	.kde4/share/apps/RecentDocuments .kde4/share/apps/gwenview/recenturls \
	\
	.local/share/Trash \
	.local/share/gvfs-metadata \
	.local/share/TelegramDesktop/tdata \
	\
	.ccnet/logs .dbus .xneur/.cache \
	.ICEauthority .Xauthority \
	.xfce4-session.verbose-log .xfce4-session.verbose-log.last \
	.xsession-errors .xsession-errors.old \
	\
	snap/skype \
#Wine,_nothing_usefull_there
	.wine .wine32 .wine64 .PlayOnLinux \
	\
#Mozilla_FF_&&_Thunderbird_Caches \
#Also,_thunderbird_Mails_stores_in_.squashfs/Mail \
	.mozilla/firefox/jx3kz6ad.default/Cache .thunderbird/93e41td3.default/ImapMail \
	.mozilla/firefox/jx3kz6ad.default/thumbnails .thunderbird/93e41td3.default/Cache \
	.mozilla/firefox/jx3kz6ad.default/storage \
	.thunderbird/93e41td3.default/Mail \
	.squashfs/Mail/Workdir .squashfs/Mail/SquashFS \
	.squashfs/Firefox/SquashFS \
	.squashfs/Firefox/New .squashfs/Firefox/NewPersistent \
	\
#Games_&_Steam \
	.config/unity3d .openttd .minecraft \
	\
	.openra \
	.local/share/Steam .steam \
	.local/share/Euro_Truck_Simulator_2 \
	.local/Uber_Entertainment \
#PhpStorm_Cache \
	.PhpStorm2017.1/system \
#Firejail_private_dir
	.firejail \
"

mk_exclude_list() {
	for i in `echo $EXCLUDE`; do
		if `echo $i | grep -qvE '^#'`; then
			echo "$EPREFIX$i";
			echo "$EPREFIX$i" | sed -e "s/$SPACE_CHARS/ /g";
		fi;
	done
}

EXCLUDE_LIST=`mk_exclude_list | sort -u`
