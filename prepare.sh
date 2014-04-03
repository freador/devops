#!/bin/bash
# This script is used for deploying default configuration for new machines that are managed by us.
# 
# What it installs and configures:
# * zabbix-agent
# * salt
# * tools: curl, wget, atop, htop, iotop, meld, git, mercurial
# * update and upgrade all packages on the machine
#
# As a rule, this script should be safe to run as many times we want.

#-- code to detect OS
lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
KERNEL=`uname -r`
ARCH=`uname -m`

if [ "${OS}" == "windowsnt" ]; then
    OS=windows
elif [ "${OS}" == "darwin" ]; then
    OS=mac
    REV=`sw_vers | grep 'ProductVersion:' | grep -o '[0-9]*\.[0-9]*\.[0-9]*'`
else
    if [ "${OS}" = "sunos" ] ; then
        DIST=solaris
        ARCH=`uname -p`
        OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" = "aix" ] ; then
        OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" = "linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            #DIST='redhat'
            DIST=`cat /etc/redhat-release |sed s/\ release.*//`
            PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/SuSE-release ] ; then
            DIST='suse'
            PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
            REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
        elif [ -f /etc/mandrake-release ] ; then
            DIST='mandrake'
            PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
        else
            which lsb_release >/dev/null
            if [[ $? -eq 0 ]]; then
                DIST=`lsb_release -i | cut -f2`
                DIST=`lowercase $DIST`
                PSEUDONAME=`lsb_release --codename | cut -f2`
                REV=`lsb_release --release | cut -f2`
            fi
        fi
        
        OS_NAME=`lowercase $OS`
        DistroBasedOn=`lowercase $DistroBasedOn`
        readonly OS
        readonly DIST
        readonly PSEUDONAME
        readonly REV
        readonly KERNEL
        readonly ARCH
    fi

fi

# Platforms: osx, linux, windows
# OS: darwin, windowsnt, ubuntu, debian, redhat, mandrake, suse
# REV: 10.9, 12.04, ...
CN="$(tput setaf 9)"
CB="$(tput setaf 2)"
#COL_GREEN="$(tput setaf 2)"
echo "os=${CB}${OS}${CN} dist=${CB}${DIST}${CN} pseudoname=${CB}${PSEUDONAME}${CN} rev=${CB}${REV}${CN} arch=${CB}${ARCH}${CN} kernel=${CB}${KERNEL}${CN}"
#echo "os=${OS} dist=${DIST} pseudoname=${PSEUDONAME} rev=${REV} arch=${ARCH} kernel=${KERNEL}"
set -ex

#exit

cd /tmp
if [ "$DIST" = "ubuntu" ]; then
    apt-get -q -y install wget
    wget http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.2-1+precise_all.deb
    dpkg -i zabbix-release_2.2-1+precise_all.deb
    mkdir -p /etc/zabbix
    wget --no-check-certificate -O /etc/zabbix/zabbix_agentd.conf https://raw.githubusercontent.com/xenserver/devops/master/etc/zabbix/zabbix_agentd.conf
    apt-get -q -y update
    apt-get -y install zabbix-agent
    apt-get -y upgrade zabbix-agent
elif [ "$DIST" = "debian" ]; then
    apt-get -q -y install wget
    wget http://repo.zabbix.com/zabbix/2.2/debian/pool/main/z/zabbix-release/zabbix-release_2.2-1+wheezy_all.deb
    dpkg -i zabbix-release_2.2-1+wheezy_all.deb
    mkdir -p /etc/zabbix
    wget --no-check-certificate -O /etc/zabbix/zabbix_agentd.conf https://raw.githubusercontent.com/xenserver/devops/master/etc/zabbix/zabbix_agentd.conf
    apt-get -q -y update
    apt-get -y install zabbix-agent
    apt-get -y upgrade zabbix-agent
else
    echo "WARN: Unable to install zabbix for this OS"
fi 