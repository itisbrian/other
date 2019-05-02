#! /bin/bash

#EPEL Repo

yum -y install epel-release
subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

#REMI


wget https://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh remi-release-7.rpm
rm -f remi-release-7.rpm
#subscription-manager repos --enable=rhel-7-server-optional-rpms

#RPMFusion

yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm 
yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm

#Elrepo

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm


#NUX


rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

#GhettoForge
rpm -Uvh http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm

#Psychotic Ninja
rpm --import http://wiki.psychotic.ninja/RPM-GPG-KEY-psychotic
rpm -ivh http://packages.psychotic.ninja/6/base/i386/RPMS/psychotic-release-1.0.0-1.el6.psychotic.noarch.rpm


#IUS


rpm -Uvh https://centos7.iuscommunity.org/ius-release.rpm



yum repolist

echo " -------------------------------------------------------"
echo " ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗"
echo "██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝"
echo "██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗  "
echo "██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝  "
echo "╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████╗"
echo " ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝"
echo " -------------------------------------------------------"

                                                                     







