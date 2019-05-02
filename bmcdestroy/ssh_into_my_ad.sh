#!/bin/bash
DOMAIN=$1
TARGET=$2
FAILEDATTEMPTS=$3

for i in `seq 0 ${FAILEDATTEMPTS}`; do
	RANDOMUSER=`shuf -n 1 lolusers.txt`
	RANDOMPASS=`shuf -n 1 lolpass.txt`
	echo "sshpass -p ${RANDOMPASS} ssh '${RANDOMUSER}\@${DOMAIN}@${TARGET}' ls"
	sshpass -p ${RANDOMPASS} ssh -oStrictHostKeyChecking=no "${RANDOMUSER}\@${DOMAIN}@${TARGET}" ls
done
