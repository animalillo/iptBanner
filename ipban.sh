#!/bin/bash
#    Shell script for banning ip lists using iptables
#
#    Copyright (C) 2014  Marcos Zuriaga Miguel <wolfi[at]wolfi.es>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#
### Set PATH ###
IPT=/sbin/iptables
WGET=/usr/bin/wget
EGREP=/bin/egrep
WC=/usr/bin/wc

#
### Vars ###
IPTABLES_LOG_MESSAGE="Bruteforce Offenders Drop"
ZONEROOT=/path/to/valid/dir/

#
### No editing below ###
SPAMLIST="IP_Bruteforce_Offenders"
DLROOT="http://www.openbl.org/lists/base.txt"
BAN_COUNT=$ZONEROOT"offenders.cnt"
tDB=$ZONEROOT"base.txt"		# Local Zone File

SELF=$(readlink -f $0)
VERSION="1.0"

case $1 in
--help)
	echo Ban current known botnets $VERSION
        echo Script usage:
	echo -e "Parameter  \t Description"
        echo -e "--help     \t Show this help message"
	echo -e "--version  \t Show the script version"
	echo -e "--download \t will download the updated IPs file"
	echo -e "--count    \t Show number of ips in current IP base file (may vary from currently banned count)"
	echo -e "\t [update]  \t Show number of ips updating the IP base file first (no banning will be done)"
	echo -e "\t [current] \t Show the number of IPS banned the last time this script was executed"
        echo -e "--clear    \t Clear all working rules from the firewall"
        echo "without parameters will apply the current most updated list"
	exit 0
;;
--clear)
        echo Clearing all rules
        $IPT -F $SPAMLIST
        $IPT -D INPUT -j $SPAMLIST
        $IPT -D OUTPUT -j $SPAMLIST
        $IPT -D FORWARD -j $SPAMLIST
        $IPT -X $SPAMLIST
        echo Clear finished
	exit 0
;;
--download)
	# get fresh zone file
        $WGET -N -P $ZONEROOT $DLROOT
	exit 0
;;
--count)
	case $2 in
	update)
		$SELF --download
	;;
	current)
		cat $BAN_COUNT
	;;
	esac
	egrep -v "^#|^$" $tDB | $WC -l
	exit 0
;;
--version)
	echo "Current verision: $VERSION"
	exit 0
;;
-*)
	$SELF --help
	exit 0
;;
*)
        #
        # create a dir
        [ ! -d $ZONEROOT ] && /bin/mkdir -p $ZONEROOT

        # Call self to clear all rules
        $SELF --clear

        #
        # create a new iptables list
        $IPT -N $SPAMLIST

        # Flush the chain if it was allready in use just in case it has some rules on it
        $IPT -F $SPAMLIST

	# Get fresh zone file
	$SELF --download

        SPAMDROPMSG=$IPTABLES_LOG_MESSAGE

        BADIPS=$(egrep -v "^#|^$" $tDB)

	# Show IPs to be banned count
	echo -n "Banning: "
	IP_COUNT=$($SELF --count)
	echo " IPs"

	# Ban the ips
	echo "Ban_start"

	spin[0]="-"
	spin[1]="/"
	spin[2]="|"
	spin[3]="\\"

	pct=0
	cnt=0
	spn=0
	pct_text="[BANNING] - 0% Curr 0"
	echo -n $pct_text
        for ipblock in $BADIPS
        do
		$IPT -A $SPAMLIST -s $ipblock -j LOG --log-prefix "$SPAMDROPMSG"
		$IPT -A $SPAMLIST -s $ipblock -j DROP

		cnt=$(($cnt+1))
		pct=$(($cnt * 100 / $IP_COUNT))

		echo -ne $pct_text | tr "[:graph:] " "\b"
		pct_text="[BANNING] ${spin[${spn}]} ${pct}%. Curr ${cnt}"

		spn=$(($spn+1))
		if [ $spn -gt 3 ]
		then
			spn=0
		fi

		echo -ne $pct_text
        done

	echo "\nRules added to iptables. Applying block..."

        # Drop everything
        $IPT -I INPUT -j $SPAMLIST
        $IPT -I OUTPUT -j $SPAMLIST
        $IPT -I FORWARD -j $SPAMLIST

	echo "All done"

	# Save current baned IP Nº
	$SELF --count > $BAN_COUNT

	exit 0
;;
esac

echo "Wops, you sould'nt be reading this error!. Something went terribly wrong." 1>&2
echo "Are you using BASH?" 1>&2
echo "Have you set up the correct path to the programs for your system?" 1>&2
exit 2

