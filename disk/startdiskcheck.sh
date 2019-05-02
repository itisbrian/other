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


#Build Date : 8/28/2018
#email brianchen@supermicro.com for bug report and changes.

#####################################################################
# This script gets executed on tty2
#
# As a note, we need some way to pass sigusr1 to the endlogging script for immediate shutdown
#
# This rolls out a 1M blocksize for spinning disks.  Different disk classes will require new parameters.
#

cat /root/stage2.conf | grep "SYS_DIR" > /root/flasher_config.sh
source /root/flasher_config.sh

RDIR="${SYS_DIR}"
OUTPUT="${RDIR}/diskcheck.txt"


echo "" > "${OUTPUT}"




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
echo -e " \e[5m                         SYSLAB File System Test.\e[25m"
echo -e "\e[32m Code in Beta Test : report errors to brianchen@supermicro.com \e[0m"
echo " "

#################################################################################################
#color correction:
# \e[32m = green
# \e[31m = red
# \e[93m = Orange
# \e[0m = white
#################################################################################################

yum -y install xfsprogs
if [ $? -ne 0 ]; then
	echo "Error: Cannot continue; unable to install xfsprogs package."
    exit 1
fi


yum -y install btrfs-progs
if [ $? -ne 0 ]; then
	echo "Error: Cannot continue; unable to install xfsprogs package."
	exit 1
fi

function wipedrives() {

	DISKPARTS=`ls /dev/sd*[0-9] 2>/dev/null`
if [ "${DISKPARTS}" != "" ]; then
        for i in `ls /dev/sd* | grep -v '[0-9]$'`; do
            echo "Partitions found on HDD/SSD disk:"
            echo "${i}"
            #wipefs -a $i 2>/dev/null
            parted -s "$i" mklabel gpt
            echo "HDD/SDD wipe finished."
        done
fi

DISKPARTS=`ls /dev/nvme*n1 2>/dev/null`
for x in $DISKPARTS; do
       echo "Secure erase" $x "."
       nvme format -s 1 "$x"
       echo "Secure erase finished."
done
}

function haltTest() {
	while [ 1 ]; do
		sleep 1
	done
}

# Create partition on disk
function makePartition() {
	#Create a new label
	parted -s "${1}" mklabel gpt
	LABELRETC=$?
	if [ $LABELRETC -ne 0 ]; then
		return $LABELRETC
	fi

	#Then make the part
	parted -s "${1}" mkpart "" xfs "0%" "${2}%"
	return $?
}

function isnvme() {
	echo ${1} |grep -i nvme &> /dev/null
	ISNVME=$?
	return $ISNVME
}

# Perform mkfs on disk
function makeFilesystem() {
	isnvme ${1}
	NVME=$?
	PT=${1}
	if [ "$NVME" -eq "0" ]; then
		PT="${1}p"
	fi
    sleep 10
	#We only ever have ONE partition
	if [ ! -b "${PT}1" ]; then
		#ls -al /dev/nvme*
		echo "ERROR: Failed at blockdev comparison (120)"
		return 1
	fi

	#Force overwrite of partition.
	mkfs.xfs -f -K "${PT}1"
	return $?
}

function clearMount() {
	isnvme ${1}
	NVME=$?
	PT=${1}
	if [ $NVME -eq 0 ]; then
		PT="${1}p"
	fi

	umount -f /tmp/mnt
        rmdir /tmp/mnt
	UMOUNTRETC=$?
	#32 is "Not mounted"; 0 is unmounted successfully; anything else is an Error and we need to halt.
	if [ $UMOUNTRETC -eq 32 ] || [ $UMOUNTRETC -eq 0 ] ; then
		echo -e "\e[32m${disk}\e[0m : Unmount Successful." 
		echo -e "${disk} : Unmount Successful." &>> $OUTPUT

	else
		echo "Error: Failed to unmount /tmp/mnt." | tee -a $OUTPUT
		rm -rf /tmp/mnt
		return 1
	fi

	
	return $?
}

# Perform mount on disk
function performMount() {
	mkdir /tmp/mnt

	isnvme ${1}
	NVME=$?
	PT=${1}

	if [ $NVME -eq 0 ]; then
		PT="${1}p"
	fi

	mount "${PT}1" /tmp/mnt
	MOUNTRETC=$?

	if [ $MOUNTRETC -ne 0 ]; then
		echo "${disk} : Error, could not mount partition. " | tee -a $OUTPUT
		clearMount
		if [ $? -ne 0 ]; then
			#We can't continue at this point.
			echo "${disk} : Error, failed to clearMount()" | tee -a $OUTPUT
			return 1
		fi

		return $MOUNTRETC
	fi

	clearMount
	return $?
}


function createbtrfs() {

	parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" btrfs "0%" "100%"
		sleep 10
		mkfs.btrfs -K -f "${disk}1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.btrfs on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi
}

function nvmecreatebtrfs() {

	parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" btrfs "0%" "100%"
		sleep 10
		mkfs.btrfs -K -f "${disk}p1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.btrfs on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}p1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi
}


function createxfs() {

		parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" xfs "0%" "100%"
        sleep 10
		mkfs.xfs -K -f "${disk}1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.xfs on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

}

function nvmecreatexfs() {

		parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" xfs "0%" "100%"
		sleep 10
		mkfs.xfs -K -f "${disk}p1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.xfs on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}p1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

}

function createext4() {

		parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" ext4 "0%" "100%"
		sleep 10
		mkfs.ext4 -E nodiscard -F "${disk}1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.ext4 on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

}
function nvmecreateext4() {

		parted -s "${disk}" mklabel gpt
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mklabel gpt on ${disk}." | tee -a $OUTPUT
			continue
		fi

		parted -s "${disk}" mkpart "" ext4 "0%" "100%"
		sleep 10
		mkfs.ext4 -E nodiscard -F "${disk}p1"
		if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkfs.ext4 on ${disk}." | tee -a $OUTPUT
			continue
		fi
	
        mkdir /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

		mount "${disk}p1" /tmp/mnt
        if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to mkdir /tmp/mnt." | tee -a $OUTPUT
			continue
		fi

}


function trim() {

        echo "" | tee -a $OUTPUT
		echo -e "\e[32m${disk}\e[0m : Starting Trim 1 " 
		echo "${disk} : Starting Trim 1 " &>> $OUTPUT
	    A1=`fstrim /tmp/mnt --verbose | grep -o -P "([0-9]*) bytes" | grep -o -P "[0-9]*"`
	    if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to fstrim /tmp/mnt." | tee -a $OUTPUT
			continue
		fi
        echo -e "\e[32m${disk}\e[0m : Trim 1 complete, byte size = \e[32m${A1}\e[0m." 
        echo -e "${disk} : Trim 1 complete, byte size = ${A1}." &>> $OUTPUT



        echo -e "\e[32m${disk}\e[0m : Starting Trim 2  " 
        echo "${disk} : Starting Trim 2 " &>> $OUTPUT
        sleep 60
        A2=`fstrim /tmp/mnt --verbose | grep -o -P "([0-9]*) bytes" | grep -o -P "[0-9]*"`
                if [ $? -ne 0 ]; then
			echo "${disk} : Error, failed to fstrim /tmp/mnt." | tee -a $OUTPUT
			continue
		fi
        echo -e "\e[32m${disk}\e[0m : Trim 2 complete, byte size = \e[32m${A2}\e[0m." 
        echo -e "${disk} : Trim 2 complete, byte size = ${A2}." &>> $OUTPUT

        echo -e "Results  : " | tee -a $OUTPUT
        if [ $A1 -eq $A2 ] && [ $A1 -ne 0 ] && [ $A2 -ne 0 ] ; then 
        echo -e "\e[32m${disk}\e[0m : Warning: Trims returned equal value." 
        echo -e "${disk} : Warning: Trims returned equal value." &>> $OUTPUT
		
	elif [ $A1 -gt $A2 ] && [ $A1 -ne 0 ] ; then 
		echo -e "\e[32m${disk}\e[0m : Pass: Trim 1 > Trim 2. " 
        echo -e "${disk} : Pass: Trim 1 > Trim 2.  " &>> $OUTPUT

    elif [ $A1 -lt $A2 ] && [ $A1 -ne 0 ] && [ $A2 -ne 0 ] ; then 
		echo -e "\e[32m${disk}\e[0m : Warning: Trim 1 < Trim 2. " 
        echo -e "${disk} : Warning: Trim 1 < Trim 2. " &>> $OUTPUT


	elif [ $A1 -eq 0 ] && [ $A2 -eq 0 ]; then
		echo -e "\e[32m${disk}\e[0m : Both trims returned 0." 
        echo -e "${disk} : Both trims returned 0." &>> $OUTPUT
	else
		echo -e "\e[32m${disk}\e[0m : Warning: Unexpected results, please verify." 
		echo -e "${disk} : Warning : Unexpected results, please verify." &>> $OUTPUT
	fi

    umount -f /tmp/mnt
    RETURN=$?
    if [ $RETURN -eq 32 ] || [ $RETURN -eq 0 ] ; then
		echo -e "\e[32m${disk}\e[0m : Unmount Successful."
		echo "${disk} : Unmount Successful." &>>$OUTPUT
	else
		echo "${disk} : Error, failed to unmount /tmp/mnt." | tee -a $OUTPUT
		exit 1
	fi

    rmdir /tmp/mnt
    if [ $? -ne 0 ]; then
			echo "Error: Failed to rmdir /tmp/mnt." | tee -a $OUTPUT
			exit 1
	fi
echo " " | tee -a $OUTPUT





}

function fastwipe() {

DISKPARTS=`ls /dev/sd*[0-9] 2>/dev/null`
if [ "${DISKPARTS}" != "" ]; then
        for i in `ls /dev/sd* | grep -v '[0-9]$'`; do
            wipefs $i -a
        done
fi

DISKPARTS=`ls /dev/nvme*n1 2>/dev/null`
for x in $DISKPARTS; do
       wipefs $x -a
done
}



#################################################################################################
#detect  partitions in drives and deletes it


echo -e " SYSLAB Disk Check"  &>> $OUTPUT
echo -e "============================================================================" &>> $OUTPUT
echo -e " "  &>> $OUTPUT

hostnamectl 2>/dev/null

if [ $? -ne 0 ]; then
	echo "Unable to obtain system information."

else
	hostnamectl &>> $OUTPUT
fi



cat /etc/redhat-release 2>/dev/null
if [ $? -ne 0 ]; then
	echo "Unable to obtain release version."
else
	cat /etc/redhat-release &>> $OUTPUT
fi

echo -e " "  &>> $OUTPUT

echo -e "============================== \e[33mDrive Detection\e[0m =============================="
echo -e "============================== Drive Detection ==============================" &>> $OUTPUT
echo " " | tee -a $OUTPUT

wipedrives

############################# color correction ##################
green='tput setaf 2'
norm='tput sgr0'
############################# start fio #########################



AA=`ls /dev/sd* 2>/dev/null | wc -l` 
AB=`ls /dev/nvme*n1 2>/dev/null | wc -l` 

echo -e "\e[32m$AA\e[0m HDD/SSD found."
echo -e "$AA HDD/SSD found." &>> $OUTPUT
echo -e "\e[32m$AB\e[0m NVMe found." 
echo -e "$AB NVMe found." &>> $OUTPUT
echo " " | tee -a $OUTPUT


if [ $AA -eq 0 ] && [ $AB -eq 0 ]; then
	echo -e "\e[31mNo disks found, bailing.\e[0m"
	echo -e "No disks found, bailing." &>> $OUTPUT
	exit 1
else
  :
fi	


echo -e "========================== \e[33mDrive Partitioning Check \e[0m =========================="
echo -e "========================== Drive Partitioning Check  ==========================" &>> $OUTPUT
echo " " | tee -a $OUTPUT


for disk in `ls /dev/sd* 2>/dev/null`; do

	# 25% use-case
	makePartition ${disk} 25
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make partition 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make partition 25% successful."
		echo -e "${disk} : Make Parition 25% successful." &>> $OUTPUT
	fi

	makeFilesystem ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make filesystem 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make filesystem 25% successful."
		echo -e "${disk} : Make filesystem 25% successful." &>> $OUTPUT

	fi

	performMount ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, disk mount 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Disk mount 25% successful."
		echo -e "${disk} : Disk mount 25% successful." &>> $OUTPUT
	fi

	#100% usage use-case

	makePartition ${disk} 100
		if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make partition 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make partition 100% successful."
		echo -e "${disk} : Make Parition 100% successful." &>> $OUTPUT
	fi

	makeFilesystem ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make filesystem 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make filesystem 100% successful."
		echo -e "${disk} : Make filesystem 100% successful." &>> $OUTPUT

	fi

	performMount ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, disk mount 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Disk mount 100% successful."
		echo -e "${disk} : Disk mount 100% successful." &>> $OUTPUT
	fi


echo " " | tee -a $OUTPUT

done

echo "" | tee -a $OUTPUT
echo "" | tee -a $OUTPUT


################ NVME  ###################################################################

for disk in `ls /dev/nvme*n1 2>/dev/null`; do
	# 25% use-case
		# 25% use-case
	makePartition ${disk} 25
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make partition 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make partition 25% successful."
		echo -e "${disk} : Make Parition 25% successful." &>> $OUTPUT
	fi

	makeFilesystem ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make filesystem 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make filesystem 25% successful."
		echo -e "${disk} : Make filesystem 25% successful." &>> $OUTPUT

	fi

	performMount ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, disk mount 25% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Disk mount 25% successful."
		echo -e "${disk} : Disk mount 25% successful." &>> $OUTPUT
	fi

	#100% usage use-case

	makePartition ${disk} 100
		if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make partition 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make partition 100% successful."
		echo -e "${disk} : Make Parition 100% successful." &>> $OUTPUT
	fi

	makeFilesystem ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, make filesystem 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Make filesystem 100% successful."
		echo -e "${disk} : Make filesystem 100% successful." &>> $OUTPUT

	fi

	performMount ${disk}
	if [ $? -ne 0 ]; then
		echo -e "${disk} : Error, disk mount 100% failed." | tee -a $OUTPUT
		continue
	else
		echo -e "\e[32m${disk}\e[0m : Disk mount 100% successful."
		echo -e "${disk} : Disk mount 100% successful." &>> $OUTPUT
	fi

echo " "| tee -a $OUTPUT	
done






echo " " | tee -a $OUTPUT



echo -e "============================== \e[33mTRIM Check\e[0m ==============================" 
echo "============================== TRIM Check ==============================" &>> $OUTPUT
echo " " | tee -a $OUTPUT


wipedrives

AA=`ls /dev/sd* 2>/dev/null | wc -l` 
AB=`ls /dev/nvme*n1 2>/dev/null | wc -l` 

if [ $AA -eq 0 ] && [ $AB -eq 0 ]; then
	echo "No drives found, exiting." | tee -a $OUTPUT
	exit 1
fi	

#if [ $AA -eq 0 ] && [ $AB -ne 0 ]; then
#	echo "Regular drives not found, NVMe drives not supported at this time." | tee -a $OUTPUT
#	echo "Check diskcheck.txt in the cburn directory for log. " | tee -a $OUTPUT
#    echo " " | tee -a $OUTPUT
#    echo "=================================== END OF TEST =========================================" | tee -a $OUTPUT
#    exit 1
#fi    

if [ $AA -gt 0 ]; then
	count=0
	for disk in `ls /dev/sd* 2>/dev/null`; do
	    counter=`hdparm -I "${disk}" | grep -i TRIM | wc -l 2>/dev/null`
        if [ $counter -gt 0 ]; then
    	((count=count+1))
        fi	
    done
        
fi

if [ $AB -gt 0 ]; then
    for disk in `ls /sys/block/ | grep -i nvme* 2>/dev/null`; do
    	counter=`cat /sys/block/"${disk}"/queue/discard_granularity`
    	if [ $counter -gt 0 ]; then
    	((count=count+1))
        fi
    done
fi

echo "TRIM Capable Drives: ${count}"

if [ $count -eq 0 ]; then
    	echo "No TRIM supported drives found." | tee -a $OUTPUT
        echo "Check diskcheck.txt in the cburn directory for log. " | tee -a $OUTPUT
        echo " " | tee -a $OUTPUT
        echo "=================================== END OF TEST =========================================" | tee -a $OUTPUT
        exit 1
fi




#DISKWIPE




echo " " | tee -a $OUTPUT
#AA=`ls /dev/sd* 2>/dev/null | wc -l` 
#AB=`ls /dev/nvme*n1 2>/dev/null | wc -l` 


#echo -e "\e[32m$AA\e[0m HDD/SSD found."
#echo -e "$AA HDD/SSD found." &>> $OUTPUT
#echo -e "\e[32m$AB\e[0m NVMe found." 
#echo -e "$AB NVMe found." &>> $OUTPUT
#echo " " | tee -a $OUTPUT


# 
#	Y88b   d88P 8888888888 .d8888b.  
#	 Y88b d88P  888       d88P  Y88b 
#	  Y88o88P   888       Y88b.      
#	   Y888P    8888888    "Y888b.   
#	   d888b    888           "Y88b. 
#	  d88888b   888             "888 
#	 d88P Y88b  888       Y88b  d88P 
#	d88P   Y88b 888        "Y8888P"  
                                 
                                 
                                 
echo -e "============================== \e[33mXFS Check\e[0m =============================="
echo -e "============================== XFS Check  =============================="  &>> $OUTPUT
echo " " | tee -a $OUTPUT
for disk in `ls /dev/sd* 2>/dev/null`; do
	hdparm -I "${disk}" | grep -i TRIM 2>/dev/null

	if [ $? -eq 0 ]; then
		
    createxfs

    trim
    fi

done

for disk in `ls /sys/block/ | grep -i nvme* 2>/dev/null`; do
	DG=`cat /sys/block/"${disk}"/queue/discard_granularity`
	if [ $DG -gt 0 ]; then
        disk="/dev/${disk}"
		nvmecreatexfs
		trim
	    
	fi
done


echo " " | tee -a $OUTPUT
    
echo -e "======================== \e[33mXFS Check Complete\e[0m ==============================" 
echo -e "======================== XFS Check Complete ==============================" &>> $OUTPUT
echo " " | tee -a $OUTPUT
# 
#	8888888888 Y88b   d88P 88888888888  d8888  
#	888         Y88b d88P      888     d8P888  
#	888          Y88o88P       888    d8P 888  
#	8888888       Y888P        888   d8P  888  
#	888           d888b        888  d88   888  
#	888          d88888b       888  8888888888 
#	888         d88P Y88b      888        888  
#	8888888888 d88P   Y88b     888        888  
wipedrives

echo " "  | tee -a $OUTPUT                             
echo -e "============================== \e[33mEXT4 Check\e[0m =============================="
echo -e "============================== EXT4 Check  =============================="  &>> $OUTPUT

for disk in `ls /dev/sd* 2>/dev/null`; do
	hdparm -I "${disk}" | grep -i TRIM 2>/dev/null

	if [ $? -eq 0 ]; then
		
        createext4


        trim
fi

done


for disk in `ls /sys/block/ | grep -i nvme* 2>/dev/null`; do
	DG=`cat /sys/block/"${disk}"/queue/discard_granularity`
	if [ $DG -gt 0 ]; then

		disk="/dev/${disk}"
		nvmecreateext4
		trim
	    
	fi
done

echo " " | tee -a $OUTPUT
echo -e "======================== \e[33mEXT4 Check Complete\e[0m ==============================" 
echo -e "======================== EXT4 Check Complete ==============================" &>> $OUTPUT                                        
echo " " | tee -a $OUTPUT

#888888b. 88888888888 8888888b.  8888888888 .d8888b.  
#888  "88b    888     888   Y88b 888       d88P  Y88b 
#888  .88P    888     888    888 888       Y88b.      
#8888888K.    888     888   d88P 8888888    "Y888b.   
#888  "Y88b   888     8888888P"  888           "Y88b. 
#888    888   888     888 T88b   888             "888 
#888   d88P   888     888  T88b  888       Y88b  d88P 
#8888888P"    888     888   T88b 888        "Y8888P"  
                                                     
wipedrives                 

                                        
                                        
echo " "  | tee -a $OUTPUT                                     
echo -e "============================== \e[33mBTRFS Check\e[0m =============================="
echo -e "============================== BTRFS Check  =============================="  &>> $OUTPUT

for disk in `ls /dev/sd* 2>/dev/null`; do
	hdparm -I "${disk}" | grep -i TRIM 2>/dev/null

	if [ $? -eq 0 ]; then
		
		createbtrfs

        trim
fi

done

for disk in `ls /sys/block/ | grep -i nvme* 2>/dev/null`; do
	DG=`cat /sys/block/"${disk}"/queue/discard_granularity`
	if [ $DG -gt 0 ]; then
        disk="/dev/${disk}"
		nvmecreatebtrfs
		trim
	    
	fi
done

echo " " | tee -a $OUTPUT
echo -e "======================== \e[33mBTRFS Check Complete\e[0m ==============================" 
echo -e "======================== BTRFS Check Complete ==============================" &>> $OUTPUT     
echo " " | tee -a $OUTPUT
echo "Performing wipefs fast wipe: "
fastwipe
echo "Wipefs fast wipe complete. "
echo " " | tee -a $OUTPUT


AZ=`cat $OUTPUT | grep -i error | wc -l`
if [ $AZ -gt 0 ] ; then
	echo -e "Errors found in the log file. " | tee -a $OUTPUT
	echo -e "Warnings found in the log file." | tee -a $OUTPUT
fi	


echo "Check diskcheck.txt in the cburn directory for log. " | tee -a $OUTPUT
echo " " | tee -a $OUTPUT
echo "=================================== END OF TEST =========================================" | tee -a $OUTPUT



