#!/bin/bash

################################################ SUPREME ###############################
echo ""
echo ""
echo -e "           \e[32m███████\e[0m╗\e[32m██\e[0m╗   \e[32m██\e[0m╗\e[32m███████\e[0m╗\e[32m██\e[0m╗      \e[32m█████\e[0m╗ \e[32m██████\e[0m╗ "
echo -e "           \e[32m██\e[0m╔════╝╚\e[32m██\e[0m╗ \e[32m██\e[0m╔╝\e[32m██\e[0m╔════╝\e[32m██\e[0m║     \e[32m██\e[0m╔══\e[32m██\e[0m╗\e[32m██\e[0m╔══\e[32m██\e[0m╗"
echo -e "           \e[32m███████\e[0m╗ ╚\e[32m████\e[0m╔╝ \e[32m███████\e[0m╗\e[32m██\e[0m║     \e[32m███████\e[0m║\e[32m██████\e[0m╔╝"
echo -e "           ╚════\e[32m██\e[0m║  ╚\e[32m██\e[0m╔╝  ╚════\e[32m██\e[0m║\e[32m██\e[0m║     \e[32m██\e[0m╔══\e[32m██\e[0m║\e[32m██\e[0m╔══\e[32m██\e[0m╗"
echo -e "           \e[32m███████\e[0m║   \e[32m██\e[0m║   \e[32m███████\e[0m║\e[32m███████\e[0m╗\e[32m██\e[0m║  \e[32m██\e[0m║\e[32m██████\e[0m╔╝"
echo -e "           ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ "
echo " "
echo -e " \e[5m                         SYSLAB KILL BMC.\e[25m"
echo -e "\e[32m Report errors to brianchen@supermicro.com \e[0m"
echo " "
sleep 5

#################################################################################################
#color correction:
# \e[32m = green
# \e[31m = red
# \e[93m = Orange
# \e[0m = white

###################################

yum -y install sshpass
yum -y install java

cat /root/stage2.conf | grep "SYS_DIR" > /root/flasher_config.sh
source /root/flasher_config.sh

RDIR="${SYS_DIR}"
mkdir ${RDIR}/bmcdestroy
OUTPUTFILETARGET="${RDIR}/bmcdestroy/bmcdestroy.log"
OUTPUTFILETARGET2="${RDIR}/bmcdestroy/redfishcurl.log"
echo "" > "${OUTPUTFILETARGET}"


#get current IPMI IP Address
echo "Checking BMC IP:" |tee -a ${OUTPUTFILETARGET}
A=`ipmitool lan print | egrep -i IP\ Address |grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'`

if [[ ${A:0:7} == "172.16." ]] ; then
	echo "${A} is on 16 network." |tee -a ${OUTPUTFILETARGET}
elif [[ ${A:0:7} == "172.31." ]]; then
    echo "${A} is on 31 network." |tee -a ${OUTPUTFILETARGET}
    echo "Connect BMC to 16 network and  try again." |tee -a ${OUTPUTFILETARGET}
    echo "Exiting." |tee -a ${OUTPUTFILETARGET}
	exit 1
else
	echo "Check your BMC Connection using 'ipmitool lan print' and try again. " |tee -a ${OUTPUTFILETARGET}
	echo "Exiting." |tee -a ${OUTPUTFILETARGET}
	exit 1
fi
########################################################################################################################################

echo "Starting BMC kill sequence:" |tee -a ${OUTPUTFILETARGET}

IP=${A} 
USER="ADMIN"
PASSWORD="ADMIN"

cd /root/bmcdestroy/smcipmitool221
./configure_my_ad.sh ${IP} ${USER} ${PASSWORD} ipmitest.bnet 172.16.96.4 TEST |tee -a ${OUTPUTFILETARGET}
./ssh_into_my_ad.sh ipmitest.bnet ${IP} 50 |tee -a ${OUTPUTFILETARGET}
cd /root

sleep 3
echo "BMC kill sequence complete." |tee -a ${OUTPUTFILETARGET}
echo "Please login to the webgui and perform some basic functions to check." |tee -a ${OUTPUTFILETARGET}

########################################################################################################################################



echo "Starting redfish API test sequence:" |tee -a ${OUTPUTFILETARGET2}

#pefroming 5 GET requests

for ((i=0;i<6;i++))
do
echo " " |tee -a ${OUTPUTFILETARGET2}
curl -k -u "test_1@ipmitest.bnet:Super123" -X GET "https://${IP}/redfish/v1/Systems/1" |tee -a ${OUTPUTFILETARGET2}
echo " " |tee -a ${OUTPUTFILETARGET2}
done

#performing 5 POST requests
postcounter=0
for ((j=0;j<6;j++))
do
echo " " |tee -a ${OUTPUTFILETARGET2}
curl -k -u "test_1@ipmitest.bnet:Super123" -H "Content-Type: application/json" -X POST -d '{"EventType":"Alert"}' "https://${IP}/redfish/v1/EventService/Actions/EventService.SubmitTestEvent" |tee -a ${OUTPUTFILETARGET2}
echo " " |tee -a ${OUTPUTFILETARGET2}
done


#performing 5 PATCH requests


for ((k=0;k<6;k++))
do
echo " " |tee -a ${OUTPUTFILETARGET2}
curl -k -u "test_1@ipmitest.bnet:Super123" -H "Content-Type: application/json" -X PATCH -d '{"Boot":{"BootSourceOverrideEnabled":"Once","BootSourceOverrideTarget":"Pxe"}}' "https://${IP}/redfish/v1/Systems/1" |tee -a ${OUTPUTFILETARGET2}
echo " " |tee -a ${OUTPUTFILETARGET2}
done


########################################################################################################################################
#PUSH RESULTS
echo " " |tee -a ${OUTPUTFILETARGET2}
echo " " |tee -a ${OUTPUTFILETARGET2}
echo " " |tee -a ${OUTPUTFILETARGET2}
if [[ `cat ${OUTPUTFILETARGET2} | grep -i "error" | wc -l` -gt 0 ]];
then
	echo "Errors found in redfish log." |tee -a ${OUTPUTFILETARGET2}
	echo "Redfish test did not pass." |tee -a ${OUTPUTFILETARGET2}
else
	echo "No errors found in redfish log." |tee -a ${OUTPUTFILETARGET2}
	echo "Redfish test passed." |tee -a ${OUTPUTFILETARGET2}
fi

echo " " |tee -a ${OUTPUTFILETARGET2}
echo "End of Test." |tee -a ${OUTPUTFILETARGET2}
echo "---------------------------------------------------------" |tee -a ${OUTPUTFILETARGET2}