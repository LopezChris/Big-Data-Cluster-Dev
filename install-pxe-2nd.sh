#!/bin/bash

printf "Task 1: Installing Necessary Tools for PXE Server....\n"
yum install -y wget git net-tools

##
# Video Tutorials Referenced:
# https://www.youtube.com/watch?v=SCovEsJ6Pe8&t=43s
#
#

# Setup a network installation server
# - Allows installation of CentOS7 on
# multiple systems using a network boot server
# - Thus, all system configured to do so will boot
# using an image provided by this server and start the
# installation program automatically
# Min of two systems is required for network installation:
# - A Server
# - A Client
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup

# Steps that must be performed to Prepare for a Network Installation:

# *****
# Step 1: Configure network server (NFS, HTTPS,HTTP, or FTP)
# to export installation tree or installation ISO image
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-making-media-additional-sources#sect-making-media-sources-network
# *****

#
# Installation Source on an HTTP Server:
# - Allows for a network-based installation using an installation
# tree, which is a directory containing extracted contents
# of binary DVD ISO image and valid .treeinfo file.
# - Installation source accessed over HTTP
#

# 1. Install httpd package
printf "Task 1: Installing HTTPD Package on PXE Server....\n"
yum install -y httpd
# 2. Copy full CentOS7 binary DVD ISO image to HTTP server
wget http://repo1.dal.innoscale.net/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso
# 3. Mount binary DVD ISO image using mount to a suitable directory
mkdir -p /mnt/centos7-install/
# Mount the CentOS7 ISO image, using the loop device, to /mnt/centos7-install/
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/sect-Using_the_mount_Command-Mounting#exam-Using_the_mount_Command-Mounting-Options
# CentOS ISO Source: http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso
mount -o loop,ro -t iso9660 ~/CentOS-7-x86_64-Minimal-1804.iso /mnt/centos7-install/
# 4. Copy files from mounted image to HTTP server
cp -r /mnt/centos7-install/ /var/www/html/
# 5. Start httpd service
# Enable httpd service, so it starts on startup
systemctl enable httpd.service
# Start httpd service
systemctl start httpd.service

# Open HTTP Firewall Port 80 to make sure the firewall allows the server
# you are installing to access the remote installation source
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

#
# Step 1 is complete, now the installation tree is accessible
# and ready to be used as the installation source.
#

# *****
# Step 2: Configure files on TFTP server necessary for network boot, configure
# DHCP, and start the TFTP service on PXE server.
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup#sect-network-boot-setup
# *****

#
# Important: GRUB2 boot loader supports network boot from HTTP in addition to a
# TFTP server. However, obtaining boot files (the kernel and initial RAM disk
# for the installer) over this protocol is very slow and "suffers a risk of
# timeout failures." Using a TFTP server to provide the boot files is recommended
#
# This warning only applies to kernel and initial RAM disk (vmlinuz and initrd).
# Obtaining the installation source from an HTTP server doesn't carry this risk.
#

# The first thing we did was set up a network server containing the package
# repositories used in the installation.

# *****
# Now we will configure the PXE server itself. This server will contain files
# necessary to boot CentOS7 and start the installation. Additionally, a DHCP
# server must be configured and all necessary services must be enabled and
# started.
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup#sect-network-boot-setup
# *****

#
# Note: the network boot configuration procedure differs based on whether the
# AMD64/Intel 64 system you want to install CentOS7 on uses BIOS or UEFI.
# Constult hardware's doc to find which system is used. We opened the firmware
# boot menu on Minnowboard to find that it uses "UEFI"
#

# Note: For configuring a network boot server for use with headless systems,
# see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-headless-installations

# *****
# 2.1: Configuring a TFTP Server for UEFI-based AMD64/Intel 64 and ARM Clients
# *****

#
# We will write a procedure to prepare the PXE server for booting UEFI-based
# AMD64/Intel 64 and ARM systems. Configuring TFTP boot for UEFI-based systems
#

# 1. Install TFTP-server package:
printf "Task 2: Installing TFTP, XINETD Package on PXE Server....\n"
yum install -y tftp-server tftp xinetd
# 2. Allow incoming connections to the TFTP service in the firewall:
firewall-cmd --permanent --add-service=tftp
firewall-cmd --reload
# 3. Configure your DHCP server to use EFI boot images packaged with shim
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/ch-dhcp_servers
# 3.1: Configuring a DHCP Server
# 1. Install DHCP Server package
printf "Task 3: Installing DHCP Package on PXE Server....\n"
yum install -y dhcp
# Installing dhcp creates a file, /etc/dhcp/dhcpd.conf, which is an empty config file
# Edit DHCP configuration file to declare options for client systems
# Keywords are case-insensitive and lines beginning with a hash sign (#) are considered comments
# There are two types of statements in the config file:
# - Parameters - state how to perform a task, whether to perform a task, or what
# network configuration options to send to the client
  # - Parameters starting with keyword 'option' are referred to as options,
  # these options control DHCP options; whereas parameters config values that are
  # not optional or control how DHCP server behaves
  # - Parameters (includes options) declared before a section enclosed in curly
  # braces ( { } ) are considered global parameters
    # Global params apply to all sections below it
# - Declarations - Describe the topology of the network, describe the clients,
# provide addresses for clients or apply a group of parameters to a group of Declarations

# Important: if config file is changed, changes don't take effect until after
# the DHCP daemon is restarted with command: systemctl restart dhcpd

# Note: Instead of changing the DHCP config file and restarting service each time,
# omshell command can be used to connect to, query and change the configuration
# of a DHCP server. Thus, all changes can be made while server is running
# Config DHCP Server, this file includes MAC Addresses and Static IPs
# Reference: https://www.centos.org/docs/5/html/Deployment_Guide-en-US/s1-dhcp-configuring-server.html
# There are options for every DHCP client in the subnet and a range
# in which the clients are assigned an IP address within that range
printf "Config DHCP Server...\n"


#
# Server Information:
# - IP Address (I get from my Server)
# - Network IP ID (found bitwise AND IP Address with Subnet Mask)
# - DHCP Server IP
# - Subnet Range (IT Provides)
# - Gateway (IT Provides)
# - TFTP Server (Same as my IP address)
# - DNS Server
#

##
# IP address to decimal
# Vise Versa
# Reference: https://gist.github.com/jjarmoc/1299906
##
# Convert IP to decimal
function atoi
{
#Returns the integer representation of an IP arg, passed in ascii dotted-decimal notation (x.x.x.x)
IP=$1; IPNUM=0
for (( i=0 ; i<4 ; ++i )); do
((IPNUM+=${IP%%.*}*$((256**$((3-${i}))))))
IP=${IP#*.}
done
echo $IPNUM
}
# Convert Decimal to IP
function itoa
{
#returns the dotted-decimal ascii form of an IP arg passed in integer format
echo -n $(($(($(($((${1}/256))/256))/256))%256)).
echo -n $(($(($((${1}/256))/256))%256)).
echo -n $(($((${1}/256))%256)).
echo $((${1}%256))
}

# Find IP Address of Server
IPADDRESS=$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
printf "Server IP Address: $IPADDRESS\n"

# Find Interface Name, ex: enp0s3
# Only needed if you are going to tinker with the network configuration file
# on a node
# kernel lists them by name, we want the one related to ethernet
# Reference: https://unix.stackexchange.com/questions/125400/how-can-i-find-available-network-interfaces
INTERFACE_NAME=$(ls /sys/class/net/ | grep -o "en.*")
printf "Network Interface Name: $INTERFACE_NAME\n"

# Find Subnetmask
# Reference to find SUBNETMASK: https://www.cyberciti.biz/faq/howto-find-subnet-mask-on-unix/
# Reference on awk: https://stackoverflow.com/questions/1506521/select-row-and-element-in-awk
SUBNETMASK=$(ifconfig $INTERFACE_NAME | awk 'FNR == 2 {print $4}')
# SUBNETMASK=255.255.255.0
printf "Server Subnetmask Address: $SUBNETMASK\n"

# Find Network IP ID = IPADRESS - SUBNETMASK
# https://networkengineering.stackexchange.com/questions/7106/how-do-you-calculate-the-prefix-network-subnet-and-host-numbers
# To get subnet or network-prefix, AND "IP address" with "subnet mask"
# Convert IP Address and SubnetMask to Decimal
IPADDRESS_NUM=$(atoi $IPADDRESS)
SUBNETMASK_NUM=$(atoi $SUBNETMASK)
# Perform Bitwise AND on IPAddress and SubnetMask
# to get Network IP Address in Decimal
NETWORK_NUM=$(( $IPADDRESS_NUM & $SUBNETMASK_NUM ))
# Convert Decimal to IP for "Network IP ID"
NETWORK_IP_ID=$(itoa $NETWORK_NUM)
printf "Network IP ID: $NETWORK_IP_ID\n"

# Set DHCP Network Range
# Add 10 IPs to the range
ADD_TO_RANGE_NUM1=$(atoi 0.0.0.20)
NETWORK_RANGE_IP_START_NUM=$(( $NETWORK_NUM + $ADD_TO_RANGE_NUM1 ))
NETWORK_RANGE_IP_START=$(itoa $NETWORK_RANGE_IP_START_NUM)
printf "Network Range IP Start: $NETWORK_RANGE_IP_START\n"
# Add 10 more IPs to range
ADD_TO_RANGE_NUM2=$(atoi 0.0.0.100)
NETWORK_RANGE_IP_END_NUM=$(( $NETWORK_NUM + $ADD_TO_RANGE_NUM2 ))
NETWORK_RANGE_IP_END=$(itoa $NETWORK_RANGE_IP_END_NUM)
printf "Network Range IP End: $NETWORK_RANGE_IP_END\n"

ADD_TO_RANGE_NUM3=$(atoi 0.0.0.10)
NETWORK_RANGE_IP_BASE_NUM=$(( $NETWORK_NUM + $ADD_TO_RANGE_NUM3 ))
NETWORK_RANGE_IP_BASE=$(itoa $NETWORK_RANGE_IP_BASE_NUM)
printf "Network Range IP Base: $NETWORK_RANGE_IP_BASE\n"
# IP Address that'll be assigned to a client based on
# their MAC address of the network interface card for each node[1-8]
# Node1 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.1)
STATIC_IP_NUM_NODE1=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE1=$(itoa $STATIC_IP_NUM_NODE1)
# Static IP Addresses were allocated by IT at 10.10.22.0/24
# STATIC_IP_NODE1=10.10.22.1
printf "Static IP Node1: $STATIC_IP_NODE1\n"
# Node2 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.2)
STATIC_IP_NUM_NODE2=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE2=$(itoa $STATIC_IP_NUM_NODE2)
# Static IP Addresses were allocated by IT at 10.10.22.0/24
# STATIC_IP_NODE2=10.10.22.2
printf "Static IP Node2: $STATIC_IP_NODE2\n"
# Node3 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.3)
STATIC_IP_NUM_NODE3=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE3=$(itoa $STATIC_IP_NUM_NODE3)
# Static IP Addresses were allocated by IT at 10.10.22.0/24
# STATIC_IP_NODE3=10.10.22.3
printf "Static IP Node3: $STATIC_IP_NODE3\n"
# Node4 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.4)
STATIC_IP_NUM_NODE4=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE4=$(itoa $STATIC_IP_NUM_NODE4)
# Static IP Addresses were allocated by IT at 10.10.22.0/24
# STATIC_IP_NODE4=10.10.22.4
printf "Static IP Node4: $STATIC_IP_NODE4\n"
# Node5 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.5)
STATIC_IP_NUM_NODE5=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE5=$(itoa $STATIC_IP_NUM_NODE5)
# STATIC_IP_NODE5=10.10.22.5
printf "Static IP Node5: $STATIC_IP_NODE5\n"
# Node6 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.6)
STATIC_IP_NUM_NODE6=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE6=$(itoa $STATIC_IP_NUM_NODE6)
# STATIC_IP_NODE6=10.10.22.6
printf "Static IP Node6: $STATIC_IP_NODE6\n"
# Node7 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.7)
STATIC_IP_NUM_NODE7=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE7=$(itoa $STATIC_IP_NUM_NODE7)
# STATIC_IP_NODE7=10.10.22.7
printf "Static IP Node7: $STATIC_IP_NODE7\n"
# Node8 Static IP
IP_ADDRESS_NUM_TO_ADD_BY=$(atoi 0.0.0.8)
STATIC_IP_NUM_NODE8=$(( $NETWORK_RANGE_IP_BASE_NUM + $IP_ADDRESS_NUM_TO_ADD_BY ))
STATIC_IP_NODE8=$(itoa $STATIC_IP_NUM_NODE8)
# STATIC_IP_NODE8=10.10.22.8
printf "Static IP Node8: $STATIC_IP_NODE8\n"

NODE1_SB=node1-sb.hortonworks.com
NODE2_SB=node2-sb.hortonworks.com
NODE3_SB=node3-sb.hortonworks.com
NODE4_SB=node4-sb.hortonworks.com
NODE5_SB=node5-sb.hortonworks.com
NODE6_SB=node6-sb.hortonworks.com
NODE7_SB=node7-sb.hortonworks.com
NODE8_SB=node8-sb.hortonworks.com

# Find Default Gateway IP in Linux (Unix/FreeBSD/OpenBSD/macOS)
# Gateway - network point acts as entrance to another network
# - associated with both router, knows where to direct packet of data
#                    and a switch, fernishes actual path in/out of gateway for given packet
# Gateway nodes - control traffic within company network or at local ISP
# Gateway node in network for enterprise is acting as Proxy server and a firewall server
# Reference: https://www.cyberciti.biz/faq/how-to-find-gateway-ip-address/
GATEWAY_ROUTER_IP=$(netstat -r -n | awk 'FNR == 3 {print $2}')
# GATEWAY_ROUTER_IP was assigned by IT
# GATEWAY_ROUTER_IP=10.10.22.254
printf "Gateway Router IP: $GATEWAY_ROUTER_IP\n"

# Find DNS1 Server IP Address being used
# Reference: https://unix.stackexchange.com/questions/28941/what-dns-servers-am-i-using
DNS1_IP=$(nmcli dev show | grep "DNS\[1\]" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
printf "DNS1 IP Address: $DNS1_IP\n"

# INIT_BOOT_FILENAME=EFI/BOOT/$(ls /var/www/html/centos7-install/EFI/BOOT/ | grep -o grubx64.*)
# printf "Initial Boot Filename: $INIT_BOOT_FILENAME\n"

cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak

# Created dhcpd.conf file to instruct DHCP server on which IP addresses will
# be assigned to particular MAC Addresses, where to find the initial boot file
# loaded by the client
tee -a /etc/dhcp/dhcpd.conf << EOF
# References:
# https://linux.die.net/man/5/dhcpd.conf
# https://linux.die.net/man/5/dhcp-options
# https://www.centos.org/forums/viewtopic.php?t=44614
# https://tools.ietf.org/html/rfc4578
allow booting;
allow bootp;
authoritative;
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

# Reference on using Dynamic Pool Range and Fixed IP addresses:
# https://www.centos.org/forums/viewtopic.php?t=44614
subnet $NETWORK_IP_ID netmask $SUBNETMASK {
    # Reference on option routers: https://linux.die.net/man/5/dhcp-options
    option routers $GATEWAY_ROUTER_IP;
    # Dynamic Pool Range: *.*.*.20 to *.*.*.100, * is specific number
    pool {
        range $NETWORK_RANGE_IP_START $NETWORK_RANGE_IP_END;
    }

    class "pxeclients" {
        match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
        # Reference on next-server and filename: https://linux.die.net/man/5/dhcpd.conf
        # TFTP Server IP Address is the IP Address of the Machine it runs on
        next-server $IPADDRESS;

        # The name of the initial boot file which is to be loaded by the client
        # Minnowboard is 00:08:A2:09.*.* architecture, so we go with x64bit
        if option architecture-type = 00:07 {
           filename "shim.efi";
        } else {
          filename "grubx64.efi";
        }
    }

}

# Reference on hosts (nodes in cluster):
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-dhcp-configuring-server
host node1-sb {
    option host-name "$NODE1_SB";
    hardware ethernet 00:08:A2:09:EF:88;
    fixed-address $STATIC_IP_NODE1;
}
host node2-sb {
    option host-name "$NODE2_SB";
    hardware ethernet 00:08:A2:09:EF:AB;
    fixed-address $STATIC_IP_NODE2;
}
host node3-sb {
    option host-name "$NODE3_SB";
    hardware ethernet 00:08:A2:09:BE:EA;
    fixed-address $STATIC_IP_NODE3;
}
host node4-sb {
    option host-name "$NODE4_SB";
    hardware ethernet 00:08:A2:09:F0:62;
    fixed-address $STATIC_IP_NODE4;
}
host node5-sb {
    option host-name "$NODE5_SB";
    hardware ethernet 00:08:A2:09:BD:E3;
    fixed-address $STATIC_IP_NODE5;
}
host node6-sb {
    option host-name "$NODE6-SB";
    hardware ethernet 00:08:A2:09:EF:92;
    fixed-address $STATIC_IP_NODE6;
}
host node7-sb {
    option host-name "$NODE7_SB";
    hardware ethernet 00:08:A2:09:F2:62;
    fixed-address $STATIC_IP_NODE7;
}
host node8-sb {
    option host-name "$NODE8_SB";
    hardware ethernet 00:08:A2:09:BE:F2;
    fixed-address $STATIC_IP_NODE8;
}
EOF

cat /etc/dhcp/dhcpd.conf

# 4. Need shim.efi file from shim package and grubx64.efi file from grub2-efi
# package in ISO image file. To access them, use commands:
# We already mounted the CentOS7 ISO image to /mnt/centos7-install/ directory
GRUB2_EFI_PACKAGE=$(ls /mnt/centos7-install/Packages/ | grep "grub2.*x64.*.rpm")
printf "Grub2-efi package: $GRUB2_EFI_PACKAGE\n"
SHIM_EFI_PACKAGE=$(ls /mnt/centos7-install/Packages/ | grep "shim.*x64.*.rpm")
printf "shim-efi package: $SHIM_EFI_PACKAGE\n"
# Copy grub2-efi package to publicly available directory
cp -pr /mnt/centos7-install/Packages/$GRUB2_EFI_PACKAGE /var/www/html/centos7-install/
# Copy shim-efi package to publicly available directory
cp -pr /mnt/centos7-install/Packages/$SHIM_EFI_PACKAGE /var/www/html/centos7-install/
umount /mnt/centos7-install/
# Extract the grub2-efi and shim-efi package
cd /var/www/html/centos7-install/
rpm2cpio $GRUB2_EFI_PACKAGE | cpio -dimv
rpm2cpio $SHIM_EFI_PACKAGE | cpio -dimv

# Already in publicly available directory,

# 5. Copy EFI boot images from your directory:
cp -r boot/efi/EFI/centos/grubx64.efi /var/lib/tftpboot/
cp -r boot/efi/EFI/centos/shim.efi /var/lib/tftpboot/
# cp -r boot/efi/EFI/centos/shimx64-centos.efi /var/lib/tftpboot/

cd ~/

# Download RPM files, place on HTTP Server in centos7-install/Packages/ for use in Kickstart %packages section
# Reference: https://centos.pkgs.org/7/epel-x86_64/epel-release-7-11.noarch.rpm.html
# Reference: https://centos.pkgs.org/7/epel-x86_64/pssh-2.3.1-5.el7.noarch.rpm.html
# Reference: https://centos.pkgs.org/7/centos-extras-x86_64/sshpass-1.06-2.el7.x86_64.rpm.html
# Reference: https://centos.pkgs.org/7/centos-x86_64/ntp-4.2.6p5-28.el7.centos.x86_64.rpm.html
# Reference: https://centos.pkgs.org/7/centos-x86_64/chrony-3.2-2.el7.x86_64.rpm.html
# Reference: https://centos.pkgs.org/7/centos-x86_64/wget-1.14-15.el7_4.1.x86_64.rpm.html
# Reference: https://centos.pkgs.org/7/centos-x86_64/net-tools-2.0-0.22.20131004git.el7.x86_64.rpm.html
mkdir -p /var/www/html/centos7-install/Extra-Packages
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm -O /var/www/html/centos7-install/Extra-Packages/epel-release-7-11.noarch.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/p/pssh-2.3.1-5.el7.noarch.rpm -O /var/www/html/centos7-install/Extra-Packages/pssh-2.3.1-5.el7.noarch.rpm
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/sshpass-1.06-2.el7.x86_64.rpm -O /var/www/html/centos7-install/Extra-Packages/sshpass-1.06-2.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/ntp-4.2.6p5-28.el7.centos.x86_64.rpm -O /var/www/html/centos7-install/Extra-Packages/ntp-4.2.6p5-28.el7.centos.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/chrony-3.2-2.el7.x86_64.rpm -O /var/www/html/centos7-install/Extra-Packages/chrony-3.2-2.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/wget-1.14-15.el7_4.1.x86_64.rpm -O /var/www/html/centos7-install/Extra-Packages/wget-1.14-15.el7_4.1.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/net-tools-2.0-0.22.20131004git.el7.x86_64.rpm -O /var/www/html/centos7-install/Extra-Packages/net-tools-2.0-0.22.20131004git.el7.x86_64.rpm

# Add TAR files for Ambari and HDP on PXE, so Ambari node can perform a local install
# Download  files, place on HTTP Server in centos7-install/localrepo/ for use in "Kickstart post install"
mkdir -p /var/www/html/centos7-install/localrepo/
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.0.0/ambari-2.7.0.0-centos7.tar.gz && \
tar xf ambari-2.7.0.0-centos7.tar.gz -C /var/www/html/centos7-install/localrepo/

mkdir -p /var/www/html/centos7-install/localrepo/hdp/
wget http://public-repo-1.hortonworks.com/HDP/centos7/3.x/updates/3.0.0.0/HDP-3.0.0.0-centos7-rpm.tar.gz && \
tar xf HDP-3.0.0.0-centos7-rpm.tar.gz -C /var/www/html/centos7-install/localrepo/hdp/

wget http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.22/repos/centos7/HDP-UTILS-1.1.0.22-centos7.tar.gz && \
tar xf HDP-UTILS-1.1.0.22-centos7.tar.gz -C /var/www/html/centos7-install/localrepo/hdp/

wget http://public-repo-1.hortonworks.com/HDP-GPL/centos7/3.x/updates/3.0.0.0/HDP-GPL-3.0.0.0-centos7-gpl.tar.gz && \
tar xf HDP-GPL-3.0.0.0-centos7-gpl.tar.gz -C /var/www/html/centos7-install/localrepo/hdp/

# Base URLS:
# Ambari Base URL: http://10.10.3.144/centos7-install/localrepo/ambari/centos7/
# HDP Base URL: http://10.10.3.144/centos7-install/localrepo/hdp/HDP/centos7/3.0.0.0-1634/
# HDP-UTILS Base URL: http://10.10.3.144/centos7-install/localrepo/hdp/HDP-UTILS/centos7/1.1.0.22/
# HDP-GPL Base URL: http://10.10.3.144/centos7-install/localrepo/hdp/HDP-GPL/centos7/3.0.0.0-1634/
AMBARI_BASE_URL="http:\/\/$IPADDRESS\/centos7-install\/localrepo\/ambari\/centos7\/"
HDP_BASE_URL="http:\/\/$IPADDRESS\/centos7-install\/localrepo\/hdp\/HDP\/centos7\/3.0.0.0-1634\/"
HDP_GPL_BASE_URL="http:\/\/$IPADDRESS\/centos7-install\/localrepo\/hdp\/HDP-GPL\/centos7\/3.0.0.0-1634\/"
HDP_UTIL_BASE_URL="http:\/\/$IPADDRESS\/centos7-install\/localrepo\/hdp\/HDP-UTILS\/centos7\/1.1.0.22\/"
# tee -a /var/www/html/centos7-install/localrepo/base-urls << EOF
# Ambari Base URL: http://$IPADDRESS/centos7-install/localrepo/ambari/centos7/
# HDP Base URL: http://$IPADDRESS/centos7-install/localrepo/hdp/HDP/centos7/3.0.0.0-1634/
# HDP-UTILS Base URL: http://$IPADDRESS/centos7-install/localrepo/hdp/HDP-UTILS/centos7/1.1.0.22/
# HDP-GPL Base URL: http://$IPADDRESS/centos7-install/localrepo/hdp/HDP-GPL/centos7/3.0.0.0-1634/
# EOF

# 1. Download the ambari.repo file from the public repository
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.0.0/ambari.repo -O /var/www/html/centos7-install/localrepo/ambari.repo
# 2. Replace the Ambari Base URL baseurl obtained when setting up your local repository
perl -pi -e "s/baseurl=.*/baseurl=$AMBARI_BASE_URL/g" /var/www/html/centos7-install/localrepo/ambari.repo
# 3. Disable gpgcheck setting it to 0
perl -pi -e "s/gpgcheck=1/gpgcheck=0/g" /var/www/html/centos7-install/localrepo/ambari.repo

# 1. Download the hdp.repo file from public repo
wget http://public-repo-1.hortonworks.com/HDP/centos7/3.x/updates/3.0.0.0/hdp.repo -O /var/www/html/centos7-install/localrepo/hdp.repo
# 2. Replace the HDP Base URL baseurl obtained when setting up your local repository
perl -pi -e "s/baseurl=http.*\/HDP\/.*/baseurl=$HDP_BASE_URL/g" /var/www/html/centos7-install/localrepo/hdp.repo
perl -pi -e "s/baseurl=http.*\/HDP-UTILS-1.1.0.22\/.*/baseurl=$HDP_UTIL_BASE_URL/g" /var/www/html/centos7-install/localrepo/hdp.repo
# 3. Disable gpgcheck setting it to 0
perl -pi -e "s/gpgcheck=1/gpgcheck=0/g" /var/www/html/centos7-install/localrepo/hdp.repo

# 1. Download the hdp.gpl.repo file from public repo
wget http://public-repo-1.hortonworks.com/HDP-GPL/centos7/3.x/updates/3.0.0.0/hdp.gpl.repo -O /var/www/html/centos7-install/localrepo/hdp.gpl.repo
# 2. Replace the HDP-GPL Base URL baseurl obtained when setting up your local repository
perl -pi -e "s/baseurl=.*/baseurl=$HDP_GPL_BASE_URL/g" /var/www/html/centos7-install/localrepo/hdp.gpl.repo
# 3. Disable gpgcheck setting it to 0
perl -pi -e "s/gpgcheck=1/gpgcheck=0/g" /var/www/html/centos7-install/localrepo/hdp.gpl.repo

# 5.5. Create "Anaconda Kickstart" for Minnowboard Turbot used in Network Install
# Reference on "Disk 'sdb' given in clerapart command does not exist" troubleshooting:
# https://access.redhat.com/discussions/746373
# Reference: https://thornelabs.net/2014/02/03/hash-roots-password-in-rhel-and-centos-kickstart-profiles.html
# Reference on sha512 hash password: http://geekcorner.sitedevelopments.net/2015/08/04/generate-sha512-password-with-centos-7fedora-7-rhel-7/
# Reference on chroot in post install script: https://listman.redhat.com/archives/kickstart-list/2002-February/msg00100.html
# Reference on using pssh: https://stackoverflow.com/questions/27718501/i-want-to-use-parallel-ssh-to-run-a-bash-script-on-multiple-servers-but-it-simp
# Reference on pssh password: https://gist.github.com/nicwolff/7c113328412765eaf83e
# Reference on pssh: https://blog.getreu.net/projects/ssh-cluster-administration/
# Reference on kickstart: https://marclop.svbtle.com/creating-an-automated-centos-7-install-via-kickstart-file
# Reference on kickstart: http://www.informit.com/articles/article.aspx?p=1157197&seqNum=4
# Reference on creating a shell script with tee, then cat:
# Make sure to download the RPM package on the PXE Server, then have the nodes
# download it from PXE server since they have access, and install it
INSTALLATION_TREE=centos7-install/
PASSWORD=$(python -c 'import crypt; print(crypt.crypt("hadoop", crypt.mksalt(crypt.METHOD_SHA512)))')
PSSH_PASSWD=hadoop
tee -a /var/www/html/centos7-install/m-turbot-ks.cfg << EOF
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use network installation
url --url="http://$IPADDRESS/$INSTALLATION_TREE"
# Use graphical install
# graphical
# Use text install
text
# Run the Setup Agent on first boot
firstboot --enable
# ignoredisk --only-use=sdb
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp3s0 --ipv6=auto --activate
network  --hostname=localhost.localdomain

# Root password
rootpw --iscrypted $PASSWORD
# System services
services --disabled="chronyd"
# System timezone
timezone America/Los_Angeles --isUtc --nontp
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr
autopart --type=lvm
# Partition clearing information
clearpart --all

# Reboot after installation is complete
# reboot

# Add CentOS7 Repository
# repo --name=centos7 --baseurl=http://mirror.centos.org/centos/7/os/x86_64/

# Add CentOS7 EXTRAS (includes SSHPASS) Repository
repo --name=extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/

# Add EPEL (includes pssh) Repository
repo --name=epel-release --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

%packages
@^minimal
@core
kexec-tools
pssh
sshpass
ntp
chrony
wget
net-tools
epel-release

# ambari
# hdp
# hdp-util
# hdp-gpl

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

# Post Installation Script
%post --log=/root/m-turbot-ks-post.log

# Reference: https://superuser.com/questions/1163676/how-to-echo-a-line-of-bash-to-file-without-executing
CHECK_IP=\$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo "CHECK_IP = \$CHECK_IP"
# Verify on node1-sb, if so, then install pssh
case "\$CHECK_IP" in
  "$STATIC_IP_NODE1") printf "Setting up Node1-sb:\n"
    printf "1. Preparing Environment....\n"
    # printf "Task 1: Installing pssh and sshpass....\n"
    # yum install -y epel-release
    # yum install -y pssh
    # yum install -y sshpass
    # Create pssh_hosts file

    printf "Task 2: Creating pssh-hosts file\n"
    echo "$STATIC_IP_NODE1" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE2" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE3" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE4" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE5" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE6" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE7" | tee -a /etc/pssh-hosts
    echo "$STATIC_IP_NODE8" | tee -a /etc/pssh-hosts

    # Creating script that will be used to add hosts info to each host in cluster
    printf "Task 3: Creating shell script to append ip map host across each node\n"
    echo "#!/bin/bash" | tee -a /append_hosts.sh
    echo "cat << EOF >> /etc/hosts" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE1 $NODE1_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE2 $NODE2_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE3 $NODE3_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE4 $NODE4_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE5 $NODE5_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE6 $NODE6_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE7 $NODE7_SB" | tee -a /append_hosts.sh
    echo "$STATIC_IP_NODE8 $NODE8_SB" | tee -a /append_hosts.sh
    echo "EOF" | tee -a /append_hosts.sh

    printf "Task 4: Setting up Password-less SSH on Each Host\n"
    # Run shell script on each host ip address provided in pssh-hosts file
    # Appends map of ip to host on each node's hosts file

    printf "Task 4.1: Editing /etc/hosts file on every host in cluster\n"
    printf "to contain IP address and Fully Qualified Domain Name...\n"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -x "-o StrictHostKeyChecking=no" -A -I < "/append_hosts.sh"

    printf "Task 4.2: Creating public and private SSH keys on Ambari Server Host\n"
    # Reference: https://stackoverflow.com/questions/10767488/automate-ssh-keygen-t-rsa-so-it-does-not-ask-for-a-passphrase
    ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''
    # Add SSH Public Key to Authorized_keys file to each target host
    printf "Task 4.3: Copy SSH Public Key into authorized_keys file\n"
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

    # Create ~/.ssh folder on each host
    printf "Task 4.4: Create ~/.ssh folder on each host\n"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "mkdir ~/.ssh"

    # Copy and Send id_rsa.pub and authorized_keys files to each host
    # Reference: https://www.tecmint.com/copy-files-to-multiple-linux-servers/
    printf "Task 4.5: Copy and Send _id_rsa.pub and authorized_keys files to each host\n"
    sshpass -p "$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av ~/.ssh/id_rsa.pub ~/.ssh/
    sshpass -p "$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av ~/.ssh/authorized_keys ~/.ssh/

    printf "Task 4.6: Set permissions ~/.ssh and authorized_keys on each host\n"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 700 ~/.ssh"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 600 ~/.ssh/authorized_keys"

    # Set Hostname for Node1
    printf "Task 4.7: Permanently set hostname\n"
    hostnamectl set-hostname $NODE1_SB

    printf "Task 4.8: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE1_SB" | tee -a /etc/sysconfig/network

    # Done setting password-less SSH
    printf "Task 5: Enable NTP on each node in Cluster and Browser Host\n"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "yum install -y ntp"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable ntpd"

    printf "Task 5.1: Enable CHRONY on each node in Cluster and Browser Host\n"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "yum install -y chrony"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl start chronyd"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable chronyd"

    printf "Task 6: Disable iptables on each host for Ambari to communicate with them\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl disable firewalld"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "service firewalld stop"

    printf "Task 7: Disable SELinux and PackageKit\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "setenforce 0"

    # Check on install host (Ambari Server) if path to refresh-packagekit.conf
    # exists, if not, then no need to disable it
    if [ -e /etc/yum/pluginconf.d/refresh-packagekit.conf ]; then
      printf "refresh-packagekit.conf exists\n";
      DISABLED=0
      perl -pi -e "s/(enabled)(.*=.*)([0-9]+)/\1\2\$DISABLED/g" /etc/yum/pluginconf.d/refresh-packagekit.conf
    else
      printf "refresh-packagekit.conf is nonexistent\n";
    fi

    # Set umask to 022 since Ambari, HDP, HDF support that value
    printf "Set unmask to 0022 since Ambari, HDP, HDF support that value\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "umask 0022"

    # On Node1 Server Host, download Ambari Repo
    prinf "Task 8: Downloading Ambari 2.7 Repo\n"
    # Install wget on each node
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "yum install -y wget"

    # Download Ambari Repo, yum install ambari-server should work cause it is local
    # 4. Place the ambari.repo file on the Ambari Server host
    wget http://$IPADDRESS/centos7-install/localrepo/ambari.repo -O /etc/yum.repos.d/ambari.repo
    # 5. Edit the priorities.conf file to add the following values
    tee -a /etc/yum/pluginconf.d/priorities.conf << EOF
    [main]
    enabled=1
    gpgcheck=0
    EOF

    # Reference for HDP3.0: https://docs.hortonworks.com/HDPDocuments/Ambari-2.7.0.0/bk_ambari-installation/content/hdp_30_repositories.html
    wget http://$IPADDRESS/centos7-install/repodata/hdp.repo -o /etc/yum.repos.d/hdp.repo

    # Confirm repository list has Ambari Repo
    REPO_CONFIG=\$(yum repolist)

    #
    HAS_AMBARI_REPO=\$(echo \$REPO_CONFIG | grep -oE '(^| )ambari-2.7.[0-9].[0-9]( |$)' | awk 'FNR == 1 {print $1}')
    if [ "\$HAS_AMBARI_REPO" = "ambari-2.7.0.0" ]; then
      printf "Task 9: Repo List has Ambari Repo, Installing ambari-server\n"
      yum localinstall -y ambari-server

      # automate ambari-server setup to accept all default values
      printf "Setting up ambari-server\n"
      ambari-server setup -s

      printf "Starting Ambari\n"
      # yum install -y net-tools
      ambari-server start
      ambari-server status
      # Now ambari UI should be reachable at: http://node1-sb.hortonworks.com:8080
    else
      printf "Repo List doesn't have Ambari Repo\n"
    fi
    ;;
  "$STATIC_IP_NODE2") printf "Setting up Node2-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE2_SB
    printf "Task 2: Appending FQDN to Network Config file\n"

    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE2_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE3") printf "Setting up Node3-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE3_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE3_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE4") printf "Setting up Node4-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE4_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE4_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE5") printf "Setting up Node5-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE5_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE5_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE6") printf "Setting up Node6-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE6_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE6_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE7") printf "Setting up Node7-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE7_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE7_SB" | tee -a /etc/sysconfig/network
    ;;
  "$STATIC_IP_NODE8") printf "Setting up Node8-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname $NODE8_SB
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=$NODE8_SB" | tee -a /etc/sysconfig/network
    ;;
  *)
    printf "Automation applies to all nodes in the cluster\n"
    ;;
esac

%end

EOF
chmod 777 /var/www/html/centos7-install/m-turbot-ks.cfg


# 6. Add a configuration file named /var/lib/tftpboot/grub.cfg
# grub.cfg consists of installation source, installation configuration
# First: inst.repo=cdrom, a target must specifies the installation source, we will use
# an installation tree (centos7-install is the extracted contents of binary DVD ISO contains images,packages,repodata,.treeinfo file)
# placed on a network location accessible over HTTP from the installation system and
# perform installation over the network using the following protocols
# Second: we specify the kickstart file location to automate the installation
# using inst.ks=host1/dir/ks.cfg, ours is inst.ks=<ip-addr>
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-making-media-additional-sources
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options#sect-boot-options-installer
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sec-customizing_the_grub_2_configuration_file
# How to add the option to auto select installing CentOS7 if user doesn't intervene after 10 seconds?
KICKSTART_FILE=m-turbot-ks.cfg
tee -a /var/lib/tftpboot/grub.cfg << EOF
set timeout=5
menuentry 'Install CentOS 7' {
  linuxefi images/pxeboot/vmlinuz ip=dhcp \
  inst.repo=http://$IPADDRESS/$INSTALLATION_TREE \
  inst.ks=http://$IPADDRESS/$INSTALLATION_TREE$KICKSTART_FILE
  initrdefi images/pxeboot/initrd.img
}
EOF

# 7. Create a "subdirectory" to store boot image files within "/var/lib/tftpboot/" directory
# and copy the boot image files to it, we use the directory "/var/lib/tftpboot/images/pxeboot/"
# mkdir -p /var/lib/tftpboot/images/CentOS-7/
mkdir -p /var/lib/tftpboot/images/pxeboot/
cp /var/www/html/centos7-install/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/images/pxeboot/
chmod 777 /var/lib/tftpboot/images/pxeboot/{vmlinuz,initrd.img}
# chmod 777 /var/lib/tftpboot/images/pxeboot/vmlinuz
# chmod 777 /var/lib/tftpboot/images/pxeboot/initrd.img

# Enable your tftp server, because default is disable, and start tftp server
# vim /etc/xinetd.d/tftp
# Disable=no
perl -pi -e "s/(disable)(.*=.*)(yes)/\1\2no/g" /etc/xinetd.d/tftp

# 8. Start and enable the services:
# DHCPD Service:
systemctl start dhcpd
systemctl enable dhcpd
# xinetd Service that manages the TFTPD Service:
systemctl start xinetd
systemctl enable xinetd
# TFTP Server Service:
systemctl start tftp
systemctl enable tftp

# Check that all necessary components are running:
# DHCP, TFTP, HTTP, XINETD

# After running the above script procedure, the PXE Boot Server is ready to serve
# PXE clients. You can now start the system you want to install CentOS 7 on,
# select PXE Boot when prompted to specify boot source and start the network installation

# Heads up, the procedure for the boot installation program from a PXE server requires the use of
# a physical network connection, such as Ethernet, it will not work with a
# wireless connection.

# Procedure Booting the installation from the Network using PXE:
# 1. Ensure network cable is attached
# Reference on Ethernets with VirtualBox Bridged Networking: https://www.virtualbox.org/manual/ch06.html
# The link indicator light on network socket should be lit, even if computer not on
# 2. Switch on computer
# 3. Depending on your hardware, some network setup and diagnostic info can be
# displayed before your computer connects to a PXE server. Once it connects, a
# menu is displayed according to the configuration of PXE server. Press the
# number key that corresponds to desired option.

#* At this point insllation program starts successfully and boot screen appears,
#* which contains info on a variety of boot options. Installatoin program auto
#* begins if you take no action within the first minute.

# Troubleshooting: cat /var/log/messages, or tail -f /var/log/messages
# dhcpd.conf message appears: 'DHCPINFORM from X.X.X.X via ethN: not authoritative for subnet X.X.X.X' appears in /var/log/messages file after configuring DHCP Server
# then check: https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk92436

# systemctl restart httpd.service tftp dhcpd
