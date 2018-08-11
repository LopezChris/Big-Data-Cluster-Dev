#!/usr/bin/env python
import os
import re
import subprocess
import platform
import netboot_tools

##
# Description:
# Preparing for a Network Installation to install CentOS7 on multiple Systems
# using network boot server. Thus, all systems configured will boot using
# an image provided by this server and start the installation automatically.
#
# Minimum of two systems is required for a network installation:
# - A server (CentOS7 VBOX VM)
#    - system running a DHCP Server, TFTP Server to provide boot files
#    - and a HTTP, FTP or NFS server which hosts the installation image
# - A client (X machines (commodity hardware or cloud))
#    - the system which the auto script is installing is CentOS7 Minimal
#    - When installation begins, the client will query DHCP Server,
#    - obtain boot files from TFTP Server and download the installation
#    - image from the HTTP, FTP, or NFS Server
# Redhat Doc Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup
##
print "Setup PXE Server For CentOS7 Network Installation\n"
# Install helper packages
packages = ['epel-release', 'wget', 'perl', 'git', 'pssh', 'sshpass',
'net-tools', 'openssl', 'shellinabox', 'cronie', 'cronie-anacron', 'httpd']

print "Installing Helper Packages\n"
for package in packages:
    try:
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("yum install -y " + package), shell=True)
    except OSError:
        print "command does not exist"

# Gather Network Data for PXE Server to Setup Internal Network for Minnowboard Cluster
print "Gathering Network Data about PXE Server\n"
netboot_tools.pxeNetTools('minnowboard')
# Network Addresses associated with PXE Server
ip_addr = netboot_tools.get_ip()
interface_name = netboot_tools.get_net_inter_card()
subnetmask = netboot_tools.get_subnetmask()
broadcast = netboot_tools.get_broadcast()
gateway_router_ip = netboot_tools.get_gateway()
subnet_ip = netboot_tools.get_subnet()
# Set Subnet IP Range for Dynamic Allocation for Random IoT Devices connecting to Minnowboard CentOS Cluster
print "Setting the Subnet Dynamic IP Range when IoT Devices connect to Minnowboard Cluster\n"
iot_start_ip_range = netboot_tools.set_ip_within_subnet(subnet_ip, 0.0.0.50)
iot_end_ip_range = netboot_tools.set_ip_within_subnet(subnet_ip, 0.0.0.100)
# Devices in CentOS Cluster
print "Setting Static IPs for Minnowboards that'll be used to build the Cluster\n"
# Minnowboard Hardware Address (Usually called MAC address)
minnowboard_mac = ["00:08:A2:09:EF:88","00:08:A2:09:EF:AB","00:08:A2:09:BE:EA",
"00:08:A2:09:F0:62","00:08:A2:09:BD:E3","00:08:A2:09:EF:92",
"00:08:A2:09:F2:62","00:08:A2:09:BE:F2"]
# Node Sandbox Hostnames
node_hostname = ["node1-sb.hortonworks.com","node2-sb.hortonworks.com",
"node3-sb.hortonworks.com","node4-sb.hortonworks.com",
"node5-sb.hortonworks.com","node6-sb.hortonworks.com",
"node7-sb.hortonworks.com","node8-sb.hortonworks.com"]
# Set Static IPs Allocated for Minnowboards in the CentOS Cluster
node_ip = []
node_ip_base = "0.0.0.2"
for node_ip_offset in range(1, (len(minnowboard_mac) + 1)):
    node_static_ip = str(node_ip_base + node_ip_offset)
    node_ip.append(netboot_tools.set_ip_within_subnet(subnet_ip, node_static_ip))

print "Configuring HTTP Server to Export Installation ISO Image\n"
