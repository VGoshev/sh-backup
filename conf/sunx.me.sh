#!/bin/sh

OUT_DIR="/data/backup"
SRC_LIST=`echo "/etc /data /var /root" |  sed -e 's, ,\n,g'`
EXCLUDE_LIST=`echo "/data/backup /var/tmp /var/logs /var/lib/docker /var/cache /root/tmp /root/.cache" | sed -e 's, ,\n,g'`
