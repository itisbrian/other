#!/bin/bash
ip="$1"
option="$2"
counter=$3
rom_1="$4"
rom_2="$5"
line="==============================================="
sum_dir="./sum"

if [ "$1" = "-h" ] || [ "$1" = "" ];then
	echo -e "$line"
	echo -e "\nUsage: ./sum_flash.sh \"BMC_ip\" \"ipmi or bios\" \"cycles\" \"rom_1\" \"rom_2\""
	echo -e "Bios flashing example: ./sum_flash.sh 172.16.1.1 bios 20 fw_1.bin fw_2.bin\n"
	echo -e "$line"
	exit 0;
fi

echo -e "$line"
echo -e "You entered: \nIPMI:$ip \nFirmware to flash: $option \nTotal cycles to flash:$counter \nFirmwares: $rom_1 and $rom_2"
echo -e "$line\n"


if [ $option = "ipmi" ]; then
	while [ $counter -gt 0 ];do
	ver=`expr $counter % 2`
	if [ $ver -eq 1 ];then
		echo "Now flashing bmc $rom_1"
		$sum_dir -i $ip -u ADMIN -p ADMIN -c updatebmc --file $rom_1 --overwrite_cfg --overwrite_sdr
		counter=`expr $counter - 1`
		echo "$counter flashing cycles left"
	
	else
		echo "Now flashing bmc $rom_2"
		$sum_dir -i  $ip -u ADMIN -p ADMIN -c updatebmc --file $rom_2 --overwrite_cfg --overwrite_sdr
		counter=`expr $counter - 1`
		echo "$counter flashing cycles left"
	fi
	sleep 30
	done

elif [ $option = "bios" ]; then
	while [ $counter -gt 0 ];do
	ver=`expr $counter % 2`
	if [ $ver -eq 1 ];then
		echo "Now flashing bios $rom_1"
		$sum_dir -i $ip -u ADMIN -p ADMIN -c updatebios --file $rom_1 --reboot
		counter=`expr $counter - 1`
		echo "$counter flashing cycles left"
	else
		echo"Now flashing bios$rom_2"
		$sum_dir -i $ip -u ADMIN -p ADMIN -c updatebios --file $rom_2 --reboot
		counter=`expr $counter - 1`
		echo "$counter flashing cycles left"
	fi
	sleep 20
	done
else
	echo "please enter either "ipmi" or "bios" for flashing option"

fi
