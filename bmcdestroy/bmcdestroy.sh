#!/bin/bash
#############################################################
#   _______     _______ _               ____
#  / ____\ \   / / ____| |        /\   |  _ \
# | (___  \ \_/ / (___ | |       /  \  | |_) |
#  \___ \  \   / \___ \| |      / /\ \ |  _ <
#  ____) |  | |  ____) | |____ / ____ \| |_) |
# |_____/   |_| |_____/|______/_/    \_\____/


#   _____ _    _ _____  _____  ______ __  __ ______
#  / ____| |  | |  __ \|  __ \|  ____|  \/  |  ____|
# | (___ | |  | | |__) | |__) | |__  | \  / | |__
#  \___ \| |  | |  ___/|  _  /|  __| | |\/| |  __|
#  ____) | |__| | |    | | \ \| |____| |  | | |____
# |_____/ \____/|_|    |_|  \_\______|_|  |_|______|





#####################################################################
# This script replaces tty4 (alt+f5) with a console executing these two python programs
#
# Requirements are:
IP=westworld.bnet

echo " " |tee -a /dev/tty0

wget "http://${IP}/bmcdestroy/getty-bmcdestroy@.service" -O "/lib/systemd/system/getty-bmcdestroy@.service" &> /dev/null
if [ $? -ne 0 ]
 then
	echo "Failed to acquire getty service for BMC Destroy." | tee /dev/tty0
	return 1
	exit 1
fi
echo "BMC Destroy Service installed." | tee /dev/tty0
############################################################################################################################
/usr/bin/systemctl daemon-reload
if [ $? -ne 0 ]
 then
	echo "Failed to reload systemd." | tee /dev/tty0
	return 2
#	exit 2
fi
echo "Systemd reload finished." | tee /dev/tty0
########################################################################################################################
mkdir /root/bmcdestroy
mkdir /root/bmcdestroy/smcipmitool221
wget "http://${IP}/bmcdestroy/smcipmitool221.tar" -O "/root/bmcdestroy/smcipmitool221/smcipmitool221.tar" &> /dev/null
if [ $? -ne 0 ]; then
	echo -e "Failed to get the tools package." | tee /dev/tty0
	return 1
#	exit 1;
fi
echo -e "SMCI tools installed." | tee /dev/tty0

tar -xf /root/bmcdestroy/smcipmitool221/smcipmitool221.tar -C /root/bmcdestroy/smcipmitool221/ --strip 1 &> /dev/null
chmod +x /root/bmcdestroy/smcipmitool221/SMCIPMITool;
###############################################################################################################################
wget "http://${IP}/bmcdestroy/killbmc16.sh" -O "/usr/local/sbin/killbmc16.sh" &> /dev/null
if [ $? -ne 0 ]
 then
	echo "Failed to get Kill BMC test." | tee /dev/tty0
	return 1
#	exit 1
fi
chmod +x /usr/local/sbin/killbmc16.sh

echo "Kill BMC test installed." | tee /dev/tty0
###############################################################################################################################
wget "http://${IP}/bmcdestroy/ssh_into_my_ad.sh" -O "/root/bmcdestroy/smcipmitool221/ssh_into_my_ad.sh" &> /dev/null
if [ $? -ne 0 ]
 then
	echo "Failed to SSH AD configuration file." | tee /dev/tty0
	return 1
#	exit 1
fi
chmod +x /root/bmcdestroy/smcipmitool221/ssh_into_my_ad.sh

echo "SSH AD configuration file installed." | tee /dev/tty0
###############################################################################################################################
wget "http://${IP}/bmcdestroy/configure_my_ad.sh" -O "/root/bmcdestroy/smcipmitool221/configure_my_ad.sh" &> /dev/null
if [ $? -ne 0 ]
 then
	echo "Failed to get AD configuration file." | tee /dev/tty0
	return 1
#	exit 1
fi
chmod +x /root/bmcdestroy/smcipmitool221/configure_my_ad.sh

echo "AD configuration file installed." | tee /dev/tty0



/usr/bin/systemctl stop getty-auto-cburn@tty2.service
/usr/bin/systemctl stop getty-auto-root@tty2.service
/usr/bin/systemctl stop getty@tty2.service
echo " " |tee -a /dev/tty0
echo -e "\e[32mStarting Kill BMC. View Progress in Alt+F2\e[0m" |tee -a /dev/tty0
echo " " |tee -a /dev/tty0
/usr/bin/systemctl start getty-bmcdestroy@tty2.service
