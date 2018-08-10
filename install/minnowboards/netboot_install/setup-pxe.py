#!/usr/bin/env python
import os
import re
import subprocess
import netboot

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
'net-tools', 'openssl', 'shellinabox']

for package in packages:
    try:
        subprocess.call(str("yum install -y " + package), shell=True)
    except OSError:
        print "command does not exist"

# Gather Network Data
ip_addr = netboot_tools.pxeTools('pxe', 'minnowboards')

ip_addr = nboot.get_ip()


interface_name =
