#!/bin/bash

IP=$1
count=0

while [ 1 ]
do
	echo "loop = " $count
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN user list
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN user list
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad server 0 1 636 20 bloomberg.com, 192.168.1.10 192.168.1.20 192.168.1.30

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad delete 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad delete 2
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad delete 3
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad delete 4
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad delete 5

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad server 1 1 636 20 adprd.bloomberg.com, 10.124.130.19 10.124.32.118 0.0.0.0

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad add 1 PVFX_OOBAUTH_2_63_1895853 adprd.bloomberg.com 3
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad add 2 PVFX_OOBAUTH_2_63_1895894 adprd.bloomberg.com 3
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad add 3 PVFX_OOBAUTH_1_63_1895853 adprd.bloomberg.com 4
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ad add 4 PVFX_OOBAUTH_1_63_1895894 adprd.bloomberg.com 4
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem sethostname dcid0027800-mgmf


	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 1 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 1 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 2 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 2 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 3 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 3 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 4 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 4 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 5 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 5 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 6 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 6 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 7 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 7 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 8 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 8 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 9 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 9 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 10 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 10 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 11 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 11 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 12 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 12 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 13 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 13 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 14 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 14 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi lan snmpcomm default
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 1 10.124.36.26
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 1 2
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert send 1
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert ip 2 10.124.137.85
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert level 2 2
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg alert send 2
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi lan snmpcomm dconms

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi power status
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi lan mac
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi ver
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi fru
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi lan dhcp enable
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi power status
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi lan mac
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi ver
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi fru

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp state enable
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp timezone +0000
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp daylight no
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp primary 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp secondary 0.0.0.0
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp state disable
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp state enable
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp timezone -0500
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp daylight yes
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp primary 10.10.10.10
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg ntp secondary 10.10.10.11

	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg dns 192.168.0.100
	java -jar SMCIPMITool.jar $IP ADMIN ADMIN ipmi oem x10cfg dns 10.10.10.10
    let count++

done

