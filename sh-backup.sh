#!/bin/sh
#set -x

###########################
# Hek-Backup Utility      #
# Author: Vladimir Goshev #
# Version: 3.1            #
###########################

PATH="${PATH}:/bin:/usr/bin"

OUT_DIR='/backup/';
SRC_LIST=`echo "/var /etc /usr/local/etc" | sed -e 's/ /\n/g'`
EXCLUDE_LIST="/var/tmp"

FULL_COUNT=2
#0 = keep all
PREFIX=""
EXTENSION="tgz"
TAR_EXTRA_ARGS="-z"
MAKE_WEEKLY=1
WEEKLY_WDAY=1
#Monday
MAKE_DAILY=1
FIND_NEWER_ARG='-newer'
TMPDIR_TPL='/tmp/satarXXXXXXXX'
###########################
MKTEMP="mktemp"
FIND="find"
TAR="tar"
RM="rm"
CHMOD="chmod"
ECHO="/bin/echo" # On ubuntu, echo of /bin/sh is too stupid =(
XARGS_NULL="xargs -0 --"
NONEXISTENT="/nonexistent"
###########################
FULL_PREFIX='full'
WEEKLY_PREFIX='diff'
DAILY_PREFIX="inc"
###########################

### Parse external config ####
[ -n "$1" -a -f "$1" ] && . $1

[ -n "$PREFIX" ] && PREFIX="${PREFIX}."
FULL_PREFIX="${PREFIX}${FULL_PREFIX}"
WEEKLY_PREFIX="${PREFIX}${WEEKLY_PREFIX}"
DAILY_PREFIX="${PREFIX}${DAILY_PREFIX}"

# For debug purposes
#ECHO_ONLY="1"
if [ "$ECHO_ONLY" = "1" ]; then
    MKTEMP="mktemp -u"
    RM="echo rm"
    TAR="echo tar"
    FIND="echo find"
    CHMOD="echo chmod"
    XARGS_NULL="xargs -0 -t --"
fi

#FIND_ONLY="1"
if [ "$FIND_ONLY" = "1" ]; then
    XARGS_NULL="xargs -0 -t --"
    trap "exit 1" TERM
    export TOP_PID=$$
fi


#### Declaration of functions ####

# Make File name,
# Arg0: Type of archive
# Arg1: Time [optional]
make_file_name() {
	ATYPE=$1
	DATE=$2
	[ -z "$DATE" ] && DATE=`date +%Y.%m.%d`

	$ECHO "${ATYPE}.${DATE}.${EXTENSION}"
}

#Make list of achived files
#Arg0 Arguments to find
#Return filename
make_file_list() {
	FNAME=`$MKTEMP $TMPDIR_TPL`

	$ECHO -n > $FNAME

	mk_fexcl() {
        $ECHO -ne "-type\0d\0(\0"
		$ECHO "$EXCLUDE_LIST" | \
		while read E; do
			if [ -n "$E" ]; then
				$ECHO -ne "-path\0"
				$ECHO -n  "$E/*"
				$ECHO -ne "\0-o\0-path\0"
				$ECHO -n  "$E"
				$ECHO -ne  "\0-o\0"
			fi
		done
        $ECHO -ne "-path\0$NONEXISTENT\0)\0-prune\0-not\0-type\0d\0-o\0"
	}
    mk_argv_null() {
		for E in $*; do
			if [ -n "$E" ]; then
                $ECHO -n "$E"
				$ECHO -ne "\0"
            fi
        done
    }
	#FEXCL=`mk_fexcl`

	$ECHO "$SRC_LIST" | \
	while read S; do
        [ -n "$S" ] && ( mk_fexcl; $ECHO -ne "-not\0-type\0d\0"; mk_argv_null $* ) | $XARGS_NULL $FIND "$S" >> $FNAME
	done

    if [ "$FIND_ONLY" = "1" ]; then
        kill -s TERM $TOP_PID
        sleep 1
        exit 1
    fi

	$ECHO $FNAME
}

#Delete old archives
purge_old_backups() {
	[ $FULL_COUNT -lt 1 ] && return

	i=0
	for F in `ls -t $FULL_PREFIX.*.tgz`; do
		if [ -f "$F" ]; then
			i=`expr $i + 1`
			if [ $i -gt $FULL_COUNT ]; then
				T=`$ECHO "$F" | sed -e "s,^$FULL_PREFIX.,,"`
				T1=`$ECHO "$T" | cut -d. -f1`
				T2=`$ECHO "$T" | cut -d. -f2`

				$RM -vf $FULL_PREFIX.$T1.$T2.*.tgz $WEEKLY_PREFIX.$T1.$T2.*.tgz $DAILY_PREFIX.$T1.$T2.*.tgz
			fi
		fi
	done
}

#Run tar
#Arg0 : File name
#Arg2 : list of archived files
run_tar() {
	FNAME=$1
	FLIST=`echo "$2" | sed -e 's/\n//g'`


	$ECHO "$EXCLUDE_LIST" | \
	( \
        while read E; do
            [ -n "$E" ] && $ECHO -ne "--exclude\0" && $ECHO -n "$E" && $ECHO -ne "\0"
        done; \
        $ECHO -ne "-T\0"; $ECHO -n "$FLIST"; $ECHO -ne "\0" \
    ) | $XARGS_NULL \
		$TAR $TAR_EXTRA_ARGS -cf "$FNAME" 2>&1
		#$TAR $TAR_EXTRA_ARGS -cf "$FNAME" -T "$FLIST" 2>&1

	$RM -vf $FLIST
	$CHMOD 0440 $FNAME
} 

#Create full Backup
create_full_backup() {
	purge_old_backups

	run_tar `make_file_name $FULL_PREFIX` `make_file_list`
}

#create diff (Weekly) Backup
create_weekly_backup() {
	[ "$MAKE_WEEKLY" = "1" ] || return 1

	BNAME=`make_file_name $WEEKLY_PREFIX`
	T1=`date +%d`
	T2=`date +%m`
	T3=`date +%Y`
	for i in `seq $T1 -1 1`; do
		ii=`expr $i + 0`
		[ $ii -lt 10 ] && ii="0$ii"
		T="$T3.$T2.$ii"
		FROM_FILE=`make_file_name "$FULL_PREFIX" "$T"`
		if [ -f $FROM_FILE ]; then 
			run_tar $BNAME `make_file_list $FIND_NEWER_ARG $FROM_FILE`
			return 0
		fi
	done

	return 2
}

#create inc (daily) Backup
create_daily_backup() {
	[ "$MAKE_DAILY" = 1 ] || return 1


	BNAME=`make_file_name $DAILY_PREFIX`
	T1=`date +%d`
	T2=`date +%m`
	T3=`date +%Y`

	## From Yesterday Inc Archive
	ii=`expr $T1 - 1`
	[ $ii -lt 10 ] && ii="0$ii"
	T="$T3.$T2.$ii"
	FROM_FILE=`make_file_name "$DAILY_PREFIX" "$T"`
	if [ -f $FROM_FILE ]; then 
		run_tar $BNAME `make_file_list $FIND_NEWER_ARG $FROM_FILE`
		return 0
	fi

	## From Weekly Diff Archive
	WDAY=`date +%u`
	[ $WDAY = 0 ] && WDAY=7
	ii=`expr $T1 - $WDAY + $WEEKLY_WDAY`
	[ $ii -lt 10 ] && ii="0$ii"
	T="$T3.$T2.$ii"
	FROM_FILE=`make_file_name "$WEEKLY_PREFIX" "$T"`
	if [ -f $FROM_FILE ]; then 
		run_tar $BNAME `make_file_list $FIND_NEWER_ARG $FROM_FILE`
		return 0
	fi

	##From newest Full Archive	
	for i in `seq $T1 -1 1`; do
		ii=`expr $i + 0`
		[ $ii -lt 10 ] && ii="0$ii"
		T="$T3.$T2.$ii"

		FROM_FILE=`make_file_name "$FULL_PREFIX" "$T"`
		if [ -f $FROM_FILE ]; then 
			run_tar $BNAME `make_file_list $FIND_NEWER_ARG $FROM_FILE`
			return 0
		fi
	done

	return 2
}


#######################################################
#Main program, Start
#######################################################

cd "$OUT_DIR" || exit 3

MDAY=`date +%-d`
WDAY=`date +%u`

if [ $MDAY = 1 ]; then
	create_full_backup
else if [ $MAKE_WEEKLY -a $WDAY = $WEEKLY_WDAY ]; then
	create_weekly_backup || create_full_backup
else if [ $MAKE_DAILY ]; then
	create_daily_backup || create_weekly_backup || create_full_backup
fi; fi; fi

#######################################################
##Main program, End
########################################################
