#!/bin/bash

##
# Setup PXE Server For CentOS7 Network Installation
# Preferred: Tested on port 1.089.1 (WORKS) private network and used IP range
# and Gateway provided by IT. My nodes have access over the internet too.
##
printf "Setup PXE Server For CentOS7 Network Installation\n"

##
# Software Packages Install
# Ref: https://www.cyberciti.biz/faq/bash-for-loop-array/
##
PACKAGES=(
epel-release
wget
perl
git
pssh
sshpass
net-tools
openssl
shellinabox
)
# Install helper software packages based on elements in packages array
for SOFTWARE in "${PACKAGES[@]}"
do
  yum install -y $SOFTWARE
done

##
# Helper Functions for setting up PXE Server
# IP address to decimal (Vise Versa)
# Reference: https://gist.github.com/jjarmoc/1299906
##

# Convert IP to decimal
#Returns the integer representation of an IP arg, passed in ascii dotted-decimal notation (x.x.x.x)
function atoi
{
IP=$1; IPNUM=0
for (( i=0 ; i<4 ; ++i )); do
((IPNUM+=${IP%%.*}*$((256**$((3-${i}))))))
IP=${IP#*.}
done
echo $IPNUM
}
# Convert Decimal to IP
#returns the dotted-decimal ascii form of an IP arg passed in integer format
function itoa
{
echo -n $(($(($(($((${1}/256))/256))/256))%256)).
echo -n $(($(($((${1}/256))/256))%256)).
echo -n $(($((${1}/256))%256)).
echo $((${1}%256))
}

##
# Variables
##
# Node Sandbox Hostnames
NODE_SB=(
node1-sb.hortonworks.com
node2-sb.hortonworks.com
node3-sb.hortonworks.com
node4-sb.hortonworks.com
node5-sb.hortonworks.com
node6-sb.hortonworks.com
node7-sb.hortonworks.com
node8-sb.hortonworks.com
)

# Minnowboard Hardware Address (Usually called MAC address)
MINNOWBOARD_MAC=(
00:08:A2:09:EF:88
00:08:A2:09:EF:AB
00:08:A2:09:BE:EA
00:08:A2:09:F0:62
00:08:A2:09:BD:E3
00:08:A2:09:EF:92
00:08:A2:09:F2:62
00:08:A2:09:BE:F2
)

# Find IP Address
IPADDRESS=$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
printf "Server IP Address: $IPADDRESS\n"

# Find Interface Name, ex: enp0s3
# kernel lists them by name, we want the one related to ethernet
INTERFACE_NAME=$(ls /sys/class/net/ | grep -o "en.*")
printf "Network Interface Name: $INTERFACE_NAME\n"

# Find Subnetmask
SUBNETMASK=$(ifconfig $INTERFACE_NAME | awk 'FNR == 2 {print $4}')
printf "Server Subnetmask Address: $SUBNETMASK\n"

# Find Broadcast IP
BROADCAST=$(ifconfig $INTERFACE_NAME | awk 'FNR == 2 {print $6}')
printf "Server Subnetmask Address: $BROADCAST\n"

# Find Gateway IP
GATEWAY_ROUTER_IP=$(netstat -r -n | awk 'FNR == 3 {print $2}')
printf "Gateway Router IP: $GATEWAY_ROUTER_IP\n"

# Subnet = IPADDRESS & SUBNETMASK
# IP Address and Subnetmask in Decimal
IPADDRESS_NUM=$(atoi $IPADDRESS)
SUBNETMASK_NUM=$(atoi $SUBNETMASK)
# Subnet IP in Decimal
SUBNET_NUM=$(( $IPADDRESS_NUM & $SUBNETMASK_NUM ))
# Convert Decimal to IP for "Subnet IP"
SUBNET_IP=$(itoa $SUBNET_NUM)
printf "Subnet IP: $SUBNET_IP\n"

# Set DHCP Subnet IP Range for Random Devices that enter this network
# Setup Range 0.0.0.50 to 0.0.0.100 for dynamic pool in case random devices
# connect to private network
# Dynamic Pool IP Start Range: *.*.*.50
ADD_TO_RANGE_NUM1=$(atoi 0.0.0.50)
SUBNET_RANGE_IP_START_NUM=$(( $SUBNET_NUM + $ADD_TO_RANGE_NUM1 ))
SUBNET_RANGE_IP_START=$(itoa $SUBNET_RANGE_IP_START_NUM)
printf "Subnet Range IP Start: $SUBNET_RANGE_IP_START\n"
# Dynamic Pool IP End Range: *.*.*.100
ADD_TO_RANGE_NUM2=$(atoi 0.0.0.100)
SUBNET_RANGE_IP_END_NUM=$(( $SUBNET_NUM + $ADD_TO_RANGE_NUM2 ))
SUBNET_RANGE_IP_END=$(itoa $SUBNET_RANGE_IP_END_NUM)
printf "Network Range IP End: $SUBNET_RANGE_IP_END\n"

# IP Range: 10.1.1.0 - 10.1.1.9 is reserved for IT devices

# IP Range: 0.0.0.10 to 0.0.0.19 will be used for PXE Server and any other
# servers needed to configure/control the devices within the private network

# 8 Devices assigned static IP addresses with base starting at Subnet + Static_IP_Base
# Ex: Subnet_Static_IP_Base=0.0.0.20+10.1.1.0 = 10.1.1.20
# Static IP Start Base for Nodes in Cluster
STATIC_IP_START_BASE_NUM=$(atoi 0.0.0.20)
SUBNET_STATIC_IP_BASE_NUM=$(( $SUBNET_NUM + $STATIC_IP_START_BASE_NUM ))
SUBNET_STATIC_IP_BASE=$(itoa $SUBNET_STATIC_IP_BASE_NUM)
printf "Subnet Static IP Base: $SUBNET_STATIC_IP_BASE\n"

# node ip number offset used to add to subnet static base
NODE_OFFSET_NUM=$(atoi 0.0.0.1)
NODE_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE_OFFSET_NUM ))

NODE_IP=()
# start at 0.0.0.20, loop based on number of devices and increment by 1
for (( I=0; I<${#MINNOWBOARD_MAC[@]}; I++ ))
do
  NODE_IP[$I]=$(itoa $NODE_IP_NUM)
  printf "NODE_IP[$I] = $NODE_IP[$I]"
  NODE_IP_NUM=$(( $NODE_IP_NUM + $NODE_OFFSET_NUM ))
done
