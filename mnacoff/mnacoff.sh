#!/bin/bash

###########################################################################################################
# Purpose : Perform A/C ON/OFF Test while taking all nodes into account 
#
# Version : 0.3 (2017/07/27)
#	    Remove possibilities for infinite loops.
#	    Increased number of attempts to check power status before failing.
#	    Recommended OFFT value for CBURN now at 1200 seconds (doubled)
#	    Added check loops to account for potential connectivity issues when BMCs are on shared LAN
#
#	    0.2 (2017/04/28)
#           Add support for selective PDU port power control
#
#           0.1 (2017/01/18)
#           Initial release
#
#           NOTE:
#           Set all nodes on the system to run the regular on/off test, but 
#           set OFFT to a big number, i.e. 1200 seconds
#
#           Arguments:
#	    <PDU IP>		IP of the PDU (currently, only Sentry unit is supported)
#           <BMC IP LIST FILE>	Basic text file with one node BMC IP on each line
#           <PDU PORTS FILE>    Basic text file with one PDU port number on each line
#
#                                                                                       Roger Chuang
###########################################################################################################

VER_STRING="0.4"

# Attempt Threshold: how many attempts the script should try before consider it a fail
ATTEMPT_THRESHOLD=1800

# Color echo
lred='\e[1;31m'
lgreen='\e[1;32m'
lwhite='\e[1;37m'
NC='\e[0m'

PORT_ON()
{
	snmpset -v2c -c private $1 1.3.6.1.4.1.1718.3.2.3.1.11.1.1.$2 integer 1 &> /dev/null
}

PORT_OFF()
{
	snmpset -v2c -c private $1 1.3.6.1.4.1.1718.3.2.3.1.11.1.1.$2 integer 2 &> /dev/null
}

PRINT_USAGE_AND_EXIT()
{
	echo -e "\n${lwhite}Version:${NC} $VER_STRING\n"
	echo -e "${lwhite}Usage:${NC} `basename $0` <PDU_IP_AND_PORTS_FILE> <BMC_IP_LIST_FILE>\n"
	echo -e "REQUIRED ARGUMENTS:"
	echo -e "<PDU_IP_AND_PORTS_FILE>\t\tFile containing IP of Sentry PDU, and optionally, the ports to be used"
	echo -e "<BMC_IP_LIST_FILE>\t\tFile containing BMC IPs for each node in system\n"
	echo -e "FILE FORMATS:"
	echo -e "<PDU_IP_AND_PORTS_FILE>\t\t${lred}[REQUIRED]${NC} PDU IP on line 1"
	echo -e "\t\t\t\t${lgreen}[OPTIONAL]${NC} PDU port number(s), each port number on its own line, starting from line 2"
	echo -e "\t\t\t\t\t   Valid Ports: 1, 2, 3, 4, 5, 6, 7, 8"
	echo -e "\t\t\t\t\t   If unspecified, all ports will be used"
	echo -e "<BMC_IP_LIST_FILE>\t\t${lred}[REQUIRED]${NC} BMC IP of all nodes in system, each BMC IP on its own line\n"
	exit
}

# Arguments checking
if [[ $# -ne 2 ]] ; then
	PRINT_USAGE_AND_EXIT
fi

if ! [[ -f $1 ]] ; then
	echo -e "\nPDU IP AND PORTS FILE [ $1 ] not found!\n"
	exit
fi

if ! [[ -f $2 ]] ; then
	echo -e "\nBMC IP LIST FILE [ $2 ] not found!\n"
	exit
fi

if [[ $( cat $1 | wc -l ) -le 0 ]] ; then
	echo -e "\nPDU IP AND PORTS FILE is empty!\n"
	exit
fi

if [[ $( cat $2 | wc -l ) -le 0 ]] ; then
	echo -e "\nBMC IP LIST FILE is empty!\n"
	exit
fi

if [[ $( cat $1 | wc -l ) -ge 9 ]] ; then
	echo -e "\nAre you using a PDU with more than 8 ports? Let me know if you are."
	echo -e "If not, it will use all 8 ports automatically when you don't specify any ports.\n"
	exit
fi

PDU_IP_LIST_F=$1
BMC_LIST_F=$2

PDU_IP=$( head -n 1 $PDU_IP_LIST_F )
USE_ALL_PDU_PORTS=1
if [[ $( cat $PDU_IP_LIST_F | wc -l ) -gt 1 ]] ; then
	USE_ALL_PDU_PORTS=0
	PDU_PORTS=$( tail -n $(( $( cat $PDU_IP_LIST_F | wc -l ) - 1 )) $PDU_IP_LIST_F )
fi
LOGFILE=${BMC_LIST_F}.log

ping -W 1 -c 1 $PDU_IP &> /dev/null
RET_CODE=$?
if [[ $RET_CODE -ne 0 ]] ; then
	if [[ $RET_CODE -eq 1 ]] ; then
		echo -e "\nThe PDU IP [ $1 ] is unreachable. Please check IP and/or network settings.\n"
	else
		echo -e "\n${lred}Invalid IP address [ $1 ]${NC}\n"
	fi
	exit
fi

PFAIL=0
for BMCIP in $( cat $BMC_LIST_F )
do
	# Ping up to 15 times, a second apart for each attempt, to take into consideration when BMC connected only on shared LAN
	# When on shared LAN, BMC connection might drop for a short period of time when node powers off
	ping -W 1 -c 1 $BMCIP &> /dev/null
	RET_CODE=$?
	P_ATTEMPTS=1
	while [[ $RET_CODE -ne 0 ]] && [[ $P_ATTEMPTS -le 15 ]]
	do
		sleep 1
		ping -W 1 -c 1 $BMCIP &> /dev/null
		RET_CODE=$?
		P_ATTEMPTS=$(( $P_ATTEMPTS + 1 ))
	done

	if [[ $RET_CODE -ne 0 ]] ; then
		if [[ $PFAIL -eq 0 ]] ; then
			echo
		fi

		PFAIL=1
	        if [[ $RET_CODE -eq 1 ]] ; then
			echo -e "FILE: ${BMC_LIST_F}, LINE: $( grep -n $BMCIP $BMC_LIST_F | awk -F ":" '{ print $1 }' ), BMC IP: [ $BMCIP ] is unreachable. Please check IP and/or network settings."
		else
			echo -e "${lred}FILE: ${BMC_LIST_F}, LINE: $( grep -n $BMCIP $BMC_LIST_F | awk -F ":" '{ print $1 }' ), BMC IP: [ $BMCIP ] is invalid!${NC}"
		fi
	fi
done

if [[ $PFAIL -eq 1 ]] ; then
	echo
	exit
fi

if [[ $USE_ALL_PDU_PORTS -eq 0 ]] ; then
	for PORT in $PDU_PORTS
	do
		if ! [[ $PORT =~ ^[1-8]$ ]] ; then
			if [[ $PFAIL -eq 0 ]] ; then
				echo
			fi

			PFAIL=1
			echo -e "PDU Port Number [ $PORT ] is invalid."
		fi
	done
fi

if [[ $PFAIL -eq 1 ]] ; then
	echo
	exit
fi

# Test Start
TOTAL_NODES=$( cat $BMC_LIST_F | wc -l )
if [[ $USE_ALL_PDU_PORTS -eq 0 ]] ; then
	TOTAL_PORTS=$( echo $PDU_PORTS | wc -w )
else
	TOTAL_PORTS=8
fi
if [[ -f $LOGFILE ]] ; then
	CYCLE=$( tail -n 1 $LOGFILE | cut -d# -f2 )
else
	CYCLE=0
fi

while true
do
	CYCLE=$(( $CYCLE + 1 ))
	echo "$( date "+%F - %R" ) #$CYCLE" >> $LOGFILE
	echo "================================================================"
	echo -e "$( date '+%Y/%m/%d %H:%M:%S' ) - CYCLE: $CYCLE"
	
	echo -n "Waiting for all nodes to power off ... "
	ALL_OFF=0
	ATTEMPTS=0
	while [[ $ALL_OFF -ne 1 ]]
	do
		ATTEMPTS=$(( $ATTEMPTS + 1 ))
		NODES_OFF=0

		sleep 1

		for NODE in $( cat $BMC_LIST_F )
		do
			ping -W 1 -c 1 $NODE &> /dev/null
			RET_CODE=$?
			P_ATTEMPTS=1
			while [[ $RET_CODE -ne 0 ]] && [[ $P_ATTEMPTS -le 15 ]]
			do
				sleep 1
				ping -W 1 -c 1 $NODE &> /dev/null
				RET_CODE=$?
				P_ATTEMPTS=$(( $P_ATTEMPTS + 1 ))
			done
			
			if [[ $RET_CODE -eq 0 ]] ; then
				ipmitool -U ADMIN -P ADMIN -H $NODE power status 2> /dev/null | grep off &> /dev/null
				if [[ $? -eq 0 ]] ; then
					NODES_OFF=$(( $NODES_OFF + 1 ))
				fi
			fi
		done

		if [[ $NODES_OFF -eq $TOTAL_NODES ]] ; then
			ALL_OFF=1
		else
			if [[ $ATTEMPTS -ge $ATTEMPT_THRESHOLD ]] ; then
				echo -e "${lred}FAIL${NC}\nPlease check system, one or more nodes might be stuck.\n"
				exit
			fi
		fi
	done
	echo -e "${lgreen}OK${NC}\n"

	# Set PDU ports power off
	if [[ $USE_ALL_PDU_PORTS -eq 0 ]] ; then	# only use specified ports
		echo -en "Setting specified ports on [ $PDU_IP ] off ..."
		for p in $PDU_PORTS
		do
			PORT_OFF $PDU_IP $p
		done
		sleep 32

		# Check port status
		OFF_COUNT=0
		ATTEMPTS=1
		while [[ $OFF_COUNT -ne $TOTAL_PORTS ]]
		do
			for p in $PDU_PORTS
			do
				# 0 = off, 1 = on
				STATUS=$( snmpget -v2c -c private $PDU_IP 1.3.6.1.4.1.1718.3.2.3.1.5.1.1.$p | awk '{ print $NF }' )
				if [[ $STATUS -eq 0 ]] ; then
					OFF_COUNT=$(( $OFF_COUNT + 1 ))
				fi
			done

			if [[ $OFF_COUNT -ne $TOTAL_PORTS ]] ; then
				if [[ $ATTEMPTS -ge 10 ]] ; then
					echo -e " ${lred}FAILED${NC}\n\n${lred}PDU ports failed to power off after 10 attempts, STOPPING ...${NC}\n"
					exit
				fi

                                echo -e " ${lred}FAILED${NC}"
                                OFF_COUNT=0

                                echo -en "Re-trying ..."
                                for p in $PDU_PORTS
                                do
                                        PORT_OFF $PDU_IP $p
                                done

				ATTEMPTS=$(( $ATTEMPTS + 1 ))

                                sleep 32
                        fi
		done

		echo -e " ${lgreen}OK${NC}\n"
	else	# Set all ports
		echo -en "Setting all ports on [ $PDU_IP ] off ..."
		for p in {1..8}
		do
			PORT_OFF $PDU_IP $p
		done
		sleep 32

		# Check port status
		OFF_COUNT=0
		ATTEMPTS=1
		while [[ $OFF_COUNT -ne $TOTAL_PORTS ]]
		do
			for p in {1..8}
			do
				# 0 = off, 1 = on
				STATUS=$( snmpget -v2c -c private $PDU_IP 1.3.6.1.4.1.1718.3.2.3.1.5.1.1.$p | awk '{ print $NF }' )
				if [[ $STATUS -eq 0 ]] ; then
					OFF_COUNT=$(( $OFF_COUNT + 1 ))
				fi
			done

			if [[ $OFF_COUNT -ne $TOTAL_PORTS ]] ; then
				if [[ $ATTEMPTS -ge 10 ]] ; then
					echo -e " ${lred}FAILED${NC}\n\n${lred}PDU ports failed to power off after 10 attempts, STOPPING ...${NC}\n"
					exit
				fi

				echo -e " ${lred}FAILED${NC}"
				OFF_COUNT=0

				echo -en "Re-trying ..."
				for p in {1..8}
				do
					PORT_OFF $PDU_IP $p
				done

				ATTEMPTS=$(( $ATTEMPTS + 1 ))

				sleep 32
			fi
		done

		echo -e " ${lgreen}OK${NC}\n"
	fi

	# Wait 30 seconds before turning on the ports again
	sleep 30

	# Set PDU ports power on
	if [[ $USE_ALL_PDU_PORTS -eq 0 ]] ; then	# only use specified ports
                echo -en "Setting specified ports on [ $PDU_IP ] on ..."
                for p in $PDU_PORTS
                do
                        PORT_ON $PDU_IP $p
                done
                sleep 5

                # Check port status
                ON_COUNT=0
		ATTEMPTS=1
                while [[ $ON_COUNT -ne $TOTAL_PORTS ]]
                do
                        for p in $PDU_PORTS
                        do
                                # 0 = off, 1 = on
                                STATUS=$( snmpget -v2c -c private $PDU_IP 1.3.6.1.4.1.1718.3.2.3.1.5.1.1.$p | awk '{ print $NF }' )
                                if [[ $STATUS -eq 1 ]] ; then
                                        ON_COUNT=$(( $ON_COUNT + 1 ))
                                fi
                        done

                        if [[ $ON_COUNT -ne $TOTAL_PORTS ]] ; then
				if [[ $ATTEMPTS -ge 10 ]] ; then
					echo -e " ${lred}FAILED${NC}\n\n${lred}PDU ports failed to power on after 10 attempts, STOPPING ...${NC}\n"
					exit
				fi

                                echo -e " ${lred}FAILED${NC}"
                                ON_COUNT=0

                                echo -en "Re-trying ..."
                                for p in $PDU_PORTS
                                do
                                        PORT_ON $PDU_IP $p
                                done

				ATTEMPTS=$(( $ATTEMPTS + 1 ))

                                sleep 5
                        fi
                done

                echo -e " ${lgreen}OK${NC}\n"
	else    # Set all ports
                echo -en "Setting all ports on [ $PDU_IP ] on ..."
                for p in {1..8}
                do
                        PORT_ON $PDU_IP $p
                done
                sleep 5

                # Check port status
                ON_COUNT=0
		ATTEMPTS=1
                while [[ $ON_COUNT -ne $TOTAL_PORTS ]]
                do
                        for p in {1..8}
                        do
                                # 0 = off, 1 = on
                                STATUS=$( snmpget -v2c -c private $PDU_IP 1.3.6.1.4.1.1718.3.2.3.1.5.1.1.$p | awk '{ print $NF }' )
                                if [[ $STATUS -eq 1 ]] ; then
                                        ON_COUNT=$(( $ON_COUNT + 1 ))
                                fi
                        done

                        if [[ $ON_COUNT -ne $TOTAL_PORTS ]] ; then
				if [[ $ATTEMPTS -ge 10 ]] ; then
					echo -e " ${lred}FAILED${NC}\n\n${lred}PDU ports failed to power on after 10 attempts, STOPPING ...${NC}\n"
					exit
				fi

                                echo -e " ${lred}FAILED${NC}"
                                ON_COUNT=0

                                echo -en "Re-trying ..."
                                for p in {1..8}
                                do
                                        PORT_ON $PDU_IP $p
                                done

				ATTEMPTS=$(( $ATTEMPTS + 1 ))

                                sleep 5
                        fi
                done

                echo -e " ${lgreen}OK${NC}\n"
        fi

	# Wait 120 seconds before proceeding to check nodes' power status
	echo -en "Waiting 120 seconds for BMCs to initialize ... "
	sleep 120
	echo -e "Done\n"

	echo -n "Checking if all nodes powered on ... "
	POWER_ON_FAILED=0
	for NODE in $( cat $BMC_LIST_F )
	do
		ping -W 1 -c 1 $NODE &> /dev/null
		RET_CODE=$?
		PING_ATTEMPT=1
		while [[ $RET_CODE -ne 0 ]]
		do
			if [[ $PING_ATTEMPT -ge $ATTEMPT_THRESHOLD ]] ; then
				echo -e "${lred}NODE [ $NODE ] BMC IP NOT REACHABLE FOR 1200 ATTEMPTS, CHECK BMC STATUS OR NETWORK FOR PROBLEMS!${NC}\n"
				exit
			fi
			sleep 1
			ping -W 1 -c 1 $NODE &> /dev/null
			RET_CODE=$?
			PING_ATTEMPT=$(( $PING_ATTEMPT + 1 ))
		done
		sleep 5

		ipmitool -U ADMIN -P ADMIN -H $NODE power status 2> /dev/null | grep on &> /dev/null
		if [[ $? -ne 0 ]] ; then
			echo -e "${lred}FAIL${NC}\nNode [ $NODE ] did not power on.\n"
			POWER_ON_FAILED=1
		fi
	done
	if [[ $POWER_ON_FAILED -eq 1 ]] ; then
		exit
	fi
	echo -e "${lgreen}OK${NC}\n"
done
