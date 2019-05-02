#!/bin/bash
counter=0
while true; do

echo -e "$( date '+%Y/%m/%d %H:%M:%S')" &>> log.txt
#time ipmitool mc info | grep -i real >> log.txt
{ time ipmitoo mc info; } 2>&1 | grep real >> log.txt
((counter+=1))
echo "cycle $counter, sleeping 60..."

sleep 60
done 
