#!/bin/bash
if [ "$#" -ne 6 ]; then
	echo "Bad input.  Usage:"
	echo "./configure_my_ad.sh <ipmi ip> <ipmi admin user> <ipmi admin pass> <ad domain> <ad server ip> <ad group>"
	exit 1
fi

if [ ! -f SMCIPMITool.jar ]; then
	echo "Cannot find smcipmitool.jar"
	exit 2
fi

IP=$1
USR=$2
PWD=$3
DOMAIN=$4
ADIP=$5
ADGRP=$6


#Clearing settings section
echo "Clearing current AD Settings"
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad server 0 1 636 20 ${DOMAIN} ${ADIP} 0.0.0.0 0.0.0.0
if [ $? -ne 0 ]; then
	echo "Error disabling AD"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad delete 1
if [ $? -ne 0 ]; then
	echo "Error clearing grp 1"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad delete 2
if [ $? -ne 0 ]; then
	echo "Error clearing grp 2"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad delete 3
if [ $? -ne 0 ]; then
	echo "Error clearing grp 3"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad delete 4
if [ $? -ne 0 ]; then
	echo "Error clearing grp 4"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad delete 5
if [ $? -ne 0 ]; then
	echo "Error clearing grp 5"
	exit -1
fi

java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad server 1 1 636 20 ${DOMAIN} ${ADIP} 0.0.0.0 0.0.0.0
if [ $? -ne 0 ]; then
	echo "Error enabling AD"
	exit -1
fi
java -jar SMCIPMITool.jar $IP $USR $PWD ipmi oem x10cfg ad add 1 ${ADGRP} ${DOMAIN} 4
if [ $? -ne 0 ]; then
	echo "Error enabling grp 1"
	exit -1
fi
