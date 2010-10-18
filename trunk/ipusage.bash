#!/bin/bash 

. ./config.bash

OUTPUT_TMP=$OUTPUT_FILE.tmp
UP="" 
DOWN="" 
NOW=`date`

echo "
<html><head><title>HM IP Usage List</title>
<script type=\"text/javascript\">
function showhide(id)
{
	if (document.getElementById)
	{
		obj = document.getElementById(id);

		if (obj.style.display == \"none\")
		{
			obj.style.display = \"\";
		} 
		else 
		{
			obj.style.display = \"none\";
		}
	}
}
</script> 
</head>
<body>
<div align=right><h1><b>Last updated $NOW</b></h1></div>
" > $OUTPUT_TMP

IFS_ORIG=$IFS
IFS=";"

for ROUTER in $ROUTERS; do

ROUTER_IP=`echo $ROUTER | awk -F "," '{print $1}'`
ROUTER_COMMUNITY=`echo $ROUTER | awk -F "," '{print $2}'`

echo "<h1>Router: $ROUTER_IP</h1>" >> $OUTPUT_TMP

if [ $DEBUG == 1 ]; then
	echo "Scanning $ROUTER_IP with community $ROUTER_COMMUNITY"
fi

IFS=$'\n'

for INTERFACEID in `snmpwalk -c $ROUTER_COMMUNITY -v2c $ROUTER_IP .1.3.6.1.4.1.9.9.128.1.1.1 |awk '{ print $4 }'`
do
	UP=""
	DOWN=""

	#####  Grab snmp data  #####
	VLANID=`snmpwalk -r 0 -c $ROUTER_COMMUNITY -v2c $ROUTER_IP .1.3.6.1.2.1.2.2.1.2.$INTERFACEID |awk '{ print $4 }'`
	VLANNUM=`echo $VLANID | sed 's/Vlan//g'`
	VLANIP=`snmpwalk -r 0 -c $ROUTER_COMMUNITY -v2c $ROUTER_IP .1.3.6.1.2.1.4.20.1.2 |grep $INTERFACEID |sed 's/\./;/' |tr '\n' ';' |awk -F ";" '{ print $2 }' |awk '{ print $1 }'`
	VLANNAME=`snmpwalk -r 0 -c $ROUTER_COMMUNITY -v2c $ROUTER_IP .1.3.6.1.4.1.9.9.46.1.3.1.1.4.1.$VLANNUM |awk '{ print $4 }'`
	NETMASK=`snmpwalk -r 0 -c $ROUTER_COMMUNITY -v 2c $ROUTER_IP .1.3.6.1.2.1.4.20.1.3.$VLANIP |awk '{ print $4 }'`

	BITS=0
	IFS=.
	for OCTET in $NETMASK
	do
		case $OCTET in
			255) let BITS=$BITS+8;;
			254) let BITS=$BITS+7;;
			252) let BITS=$BITS+6;;
			248) let BITS=$BITS+5;;
			240) let BITS=$BITS+4;;
			224) let BITS=$BITS+3;;
			192) let BITS=$BITS+2;;
			128) let BITS=$BITS+1;;
			0) ;;
		esac
	done

	if [ $DEBUG == 1 ]; then
		echo "    Found VLAN $VLANID with IP: $VLANIP/$BITS - NETMASK: $NETMASK"
	fi

	IFS=$'\n'

	echo "<b><a href=\"javascript:showhide('$VLANID')\">$VLANID</a> - </b>Name:<b> $VLANNAME - </b>Default Gateway:<b> $VLANIP - </b>Netmask:<b> $NETMASK</b><blockquote><div id=$VLANID style=\"display: none;\"><pre>" >> $OUTPUT_TMP

#	echo "nmap -n -sP $VLANIP/$BITS |grep Host |sed 's/  */;/g'";

	for LINE in `nmap -v -n -sP $VLANIP/$BITS |grep Host |sed 's/  */;/g'`
	do
		IP=`echo $LINE |awk -F ";" '{print $2}'`
		STATUS=`echo $LINE |awk -F ";" '{print $4}'`
		DNS=`nslookup $IP |grep name |awk '{print $4}' | sed ':start /^.*$/N;s/\n/, /g; t start' |sed 's/com\.$/com/g'`

		if [[ $STATUS == *up* ]]
		then
			DNS="<span style='color: darkgray;'>[`snmpget -r 0 -On -c $SYSTEM_COMMUNITY -v 2c $IP .1.3.6.1.2.1.1.5.0 2>/dev/null |awk '{ print $4 }' |sed 's/\"//g'`]</span> $DNS"
			UP=$UP"<div style='color:red;'><b>$START $IP - $DNS</b></div>"
		else
			DOWN=$DOWN"<div style='color:green;'><b>$START $IP - $DNS</b></div>"
		fi

	done

	echo "<table><tr><th width=\"50%\">IP Addresses UP</th><th>IP Addresses DOWN (available)</th></tr><tr><td valign=top>$UP</td><td valign=top>$DOWN</td></tr></table>" >> $OUTPUT_TMP
	
	echo "" >> $OUTPUT_TMP
	echo "</pre></div></blockquote><br>" >> $OUTPUT_TMP


done

IFS=$IFS_ORIG

done

echo '<div align="center">Powered by IP Usage - <a href="http://code.google.com/p/ipusage/">http://code.google.com/p/ipusage/</a>.' >> $OUTPUT_TMP

mkdir -p $HISTORY_DIR
mv $OUTPUT_FILE $HISTORY_DIR/history.html.`date +"%Y%m%d.%H%M"` 2>/dev/null
mv $OUTPUT_TMP $OUTPUT_FILE 2>/dev/null
