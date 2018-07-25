#!/bin/bash

##
# Prequisite: Need to get internet access if don't have it already
# User doesn't have internet on guest vm, so share script by USB
##

# Static IP falls within IP Range Provided by IT: 10.1.1.0/24
STATIC_IPADDRESS="10.1.1.2"

# Based on IP Range Allocated: 10.1.1.0/24
SUBNETMASK="255.255.255.0"

# IT Provided, Default Gateway IP
# Acts as a way for the nodes to get access to the internet
GATEWAY_ROUTER_IP="10.1.1.1"

##
# Prequisite: Need to get internet access
##

# Update ifcfg-enp0s3, so PXE Server in the cluster network can get access to the internet
sed -i -e "s/BOOTPROTO=dhcp/BOOTPROTO=static/g" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "s/ONBOOT=no/ONBOOT=yes/g" /etc/sysconfig/network-scripts/ifcfg-enp0s3
# Append new information
# Only append if file doesn't contain IPADDR, NETMASK, GATEWAY

tee -a /etc/sysconfig/network-scripts/ifcfg-enp0s3 << EOF
IPADDR=$STATIC_IPADDRESS
NETMASK=$SUBNETMASK
GATEWAY=$GATEWAY_ROUTER_IP
EOF

# Update /etc/resolv.conf with Public DNS (name servers)
# Public DNS Server List:
# - https://public-dns.info/nameserver/us.html
# - https://www.lifewire.com/free-and-public-dns-servers-2626062
tee -a /etc/resolv.conf << EOF
# Free and Public DNS (nameserver) Server List
# Google
nameserver 8.8.8.8
# Mountain View (iCloud DNS Bypass)
nameserver 104.155.28.90
# Los Angeles
nameserver 216.116.96.2
EOF

service network restart
