#!/usr/bin/env python
import os
import netboot_tools
import subprocess
##
# Only use if setting up cluster in Test Network setup by IT
# Else, your Internet Service Provider's DHCP Server will assign you an IP
# Get Internet Access for CentOS7 PXE Node
# IT will provide: IP Address Range for static IPs, for ex: 10.1.1.0/24
# IT will provide: Gateway Router IP Address, for ex: 10.1.1.1
# IT will have IP addresses reserved for setting up Network:
# for ex: 10.1.1.0 - 10.1.1.9
# ex: 10.1.1.0 is Primary Firewall and 10.1.1.2 is Standby Firewall
##
static_ipaddress = "10.1.1.11" # IP falls within IP Range: 10.1.1.0/24
subnetmask = "255.255.255.0" # Based on IP Range Allocated: 10.1.1.0/24
gateway_router_ip = "10.1.1.1" # A means for nodes to get internet access
google_pdns = "8.8.8.8" # Public Domain Name Servers
mview_pdns = "104.155.28.90"
lapdns = "216.116.96.2"

# Update ifcfg-enp0s3, so PXE Server in the cluster network can get access to the internet
network_file = "/etc/sysconfig/network-scripts/ifcfg-enp0s3"
# Search for regex pattern and replace with repl string in network_file
ifcfg_file = netboot_tools.fileTools(network_file)
regex_pattern = [r'BOOTPROTO=dhcp', r'ONBOOT=no']
repl = ['BOOTPROTO=static', 'ONBOOT=yes']
for regp, r in zip(regex_pattern, repl):
    ifcfg_file.repl_file_string(regp, r)

# Only append IPADDR, NETMASK, GATEWAY to network_file if file doesn't contain it
regex_pattern = [r'IPADDR=', r'NETMASK=', r'GATEWAY=']
property = ['IPADDR=', 'NETMASK=', 'GATEWAY=']
value = [static_ipaddress, subnetmask, gateway_router_ip]
for regp, p, v in zip(regex_pattern, property, value):
    ifcfg_file.append_if_no_match(regp, p, v)

# Update /etc/resolv.conf with Public DNS (name servers)
dns_file = "/etc/resolv.conf"
resolv_file = netboot_tools.fileTools(dns_file)
regex_pattern = [r'8.8.8.8', r'104.155.28.90', r'216.116.96.2']
value = [google_pdns, mview_pdns, lapdns]
for regp, v in zip(regex_pattern, value):
    resolv_file.append_if_no_match(regp, "nameserver ", v)

# Restart Network
try:
    subprocess.call("service network restart", shell=True)
except OSError:
    print "command does not exist"
