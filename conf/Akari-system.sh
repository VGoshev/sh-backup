#!/bin/sh

SPACE_CHARS="_"
EPREFIX=""
OUT_DIR="/home/backup/sunx/System/new"
SRC_LIST=`echo "/etc /var/lib /root " | sed -e 's/ /\n/g'`
EXCLUDE="/var/log /var/tmp /home/backup \
	/var/spool/exim/msglog /var/lib/layman /var/lib/docker \
	/root/tmp /home/sunx/tmp /root/.cache \
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
