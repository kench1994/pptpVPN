#!/bin/bash 

echo "############################"
echo "# PPTP VPN CONFIG"
echo "# Env: Debian/Ubuntu"
echo "# Created on 2017.02.22"
echo "# Version: 1.0"
echo "############################"
echo ""


RESET="\e[0m"
RED="${RESET}\e[0;31m"
GREEN="${RESET}\e[0;32m"
YELLOW="${RESET}\e[0;33m"
BLUE="${RESET}\e[0;34m"
PINK="${RESET}\e[0;35m"
CYAN="${RESET}\e[0;36m"


WORK_DIR="/home/kench/Downloads/"
CONFIG_FILE_NAME="VPNconfig"
CONFIG_FILE="$WORK_DIR""$CONFIG_FILE_NAME"
DeviceName=$(ifconfig | grep link -B2 | awk -F ':' '{print $1}' |head -1)
#LocalIp=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
#ServerIp=$(cat $CONFIG_FILE | grep ServerIp | awk '{print $2}') #not used now



_p() {
    printf "$@"
    printf "${RESET}\n"
}

function _checkFile(){
if [ -f $1 ]; then
	#判断文件存在,首次执行会进行备份
	if [ ! -f $1.bak ]; then
		cp $1 $1.bak
	fi
	#判断用户可写
	#if [ ! -w $1 ]; then 
	#判断普通用户可写
	rwx=$(ls -l /etc/apt/sources.list | awk -F '-' '{print $3}') 
	if [[  $rwx == r* ]];then 
	sudo chmod a+rw "$1"
#	else 
#		_p $1 can write
	fi	
else
	_p "${RED}$1 not exit\n"
fi
}


function _easyJasonParse(){
#used sample:
#_easyJasonParse vpn1 ServerIp
#$2=SearchTerm
#    "VpnName": "testvpn",
#    "ServerIp": "1.1.1.1",
#    "UserName": "x1x",
#    "PassWorld": "x2x"
cat $CONFIG_FILE | jq .| grep "$1" -A4 | sed '1d' | grep $2 | awk -F '"' '{print $4}'
#cat $CONFIG_FILE | jq . | grep '^  "$1' -A4

}
#cat $CONFIG_FILE | jq .

#sudo pptpsetup --create vpn --server ServerIp --username vpn1560 --password vpntm --encrypt --start
function _SetupVpn(){
#sample: _SetupVpn vpn1
#vpn1是网页中vpn选择的代号，项目名称
	VpnName=$(_easyJasonParse $1 VpnName)
	ServerIp=$(_easyJasonParse $1 ServerIp)
	UserName=$(_easyJasonParse $1 UserName)
	PassWorld=$(_easyJasonParse $1 PassWorld)
	sudo pptpsetup --create $VpnName --server $ServerIp --username $UserName --password $PassWorld --encrypt
}


function _ConnectVpn(){
	VpnName=$(_easyJasonParse $1 VpnName)
	sudo pon $VpnName
	sudo route add -net 0.0.0.0 dev ppp0
}

function _DisConnectVpn(){
	VpnName=$(_easyJasonParse $1 VpnName)
	sudo poff $VpnName
	sudo route del -net 0.0.0.0 dev ppp0
}

function _EditVpn(){
	_RemoveVpn $1
	_SetupVpn $1
}

function _RemoveVpn(){
#sample： _RemoveVpn vpn1
	VpnName=$(_easyJasonParse $1 VpnName)
	UserName=$(_easyJasonParse $1 UserName)
	sudo rm -rf /etc/ppp/peers/$VpnName
	sudo sed -i '/^$/d' /etc/ppp/chap-secrets
	sudo sed -i '/added by/d' /etc/ppp/chap-secrets
	#根据账号名删除
	temp=$(grep -rn "$UserName" /etc/ppp/chap-secrets | awk -F ':' '{print $1}')
	sudo sed -i "$temp d" /etc/ppp/chap-secrets
}

#test
cat $CONFIG_FILE | jq '.vpn1' 
_RemoveVpn vpn1
#sleep 3
#_SetupVpn vpn1
#sleep 3
#_ConnectVpn vpn1
#sleep 3
#sudo plog