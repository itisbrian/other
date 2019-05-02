#!/bin/bash
# xrandr.sh
#If no argument is specified, ask for it and exit

if [[ "$1" == "-h" ]]; then
echo " "
echo "Usage example : ./screen.sh width height refreshRate"
echo "Standard resolutions (16:9) : 1024x576 1152x658 1280x720 1366x768 1600x900 1920x1080 2560x1440 3840x2160"
echo "Please make sure your monitor supports the resolution before committing."
echo " "
exit
fi


if [[ -z "$@" ]];
then
echo " "
echo "An argument is needed to run this script. try -h."
echo " " 
exit
else
arg="$@"
#Basic check to make sure argument number is valid. If not, display error and exit
if [[ $(($(echo $arg | grep -o "\s" | wc --chars) / 2 )) -ne 2 ]];
then
echo " "
echo "Invalid Parameters. Use -h to see a list of standard resolutions."
echo "For example "1920 1080 60""
echo "Please make sure your monitor supports the resolution before committing."
echo " "
exit
fi

#Save stuff in variables and then use xrandr with those variables
modename=$(echo $arg | sed 's/\s/_/g')
display=$(xrandr | grep -Po '.+(?=\sconnected)')
if [[ "$(xrandr|grep $modename)" = "" ]];
then
xrandr --newmode $modename $(gtf $(echo $arg) | grep -oP '(?<="\s\s).+') &&
xrandr --addmode $display $modename
fi
xrandr --output $display --mode $modename

#If no error occurred, display success message
if [[ $? -eq 0 ]];
then
echo "Display changed successfully to $arg"
fi
fi
