#!/bin/bash

# Setup PXE Server For CentOS7 Network Installation
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
# - A client (8 Minnowboards)
#    - the system which the auto script is installing is CentOS7 Minimal
#    - When installation begins, the client will query DHCP Server,
#    - obtain boot files from TFTP Server and download the installation
#    - image from the HTTP, FTP, or NFS Server
# Redhat Doc Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup
##

printf "Setup PXE Server For CentOS7 Network Installation\n"

##
# Helper Functions for setting up PXE Server
# IP address to decimal (Vise Versa)
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

##
# Useful variables that hold information about the PXE Server
# - Provided by my Server: IP Address
# - Provided by IT: IP Range Allocated (for nodes), Gateway IP, Subnet Mask
##
IPADDRESS=$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
printf "Server IP Address: $IPADDRESS\n"

# Based on IP Range Allocated: 10.1.1.0/24
SUBNETMASK="255.255.255.0"

# IT Provided, Default Gateway IP
# Acts as a way for the nodes to get access to the internet
GATEWAY_ROUTER_IP="10.1.1.1"

# Subnet = IPADDRESS & SUBNETMASK
# IP Address and Subnetmask in Decimal
IPADDRESS_NUM=$(atoi $IPADDRESS)
SUBNETMASK_NUM=$(atoi $SUBNETMASK)
# Subnet IP in Decimal
SUBNET_NUM=$(( $IPADDRESS_NUM & $SUBNETMASK_NUM ))
# Convert Decimal to IP for "Subnet IP"
SUBNET_IP=$(itoa $NETWORK_NUM)
printf "Subnet IP: $SUBNET_IP\n"

# Set DHCP Subnet IP Range for Random Devices that enter this network
# IP Start Range: *.*.*.30
ADD_TO_RANGE_NUM1=$(atoi 0.0.0.30)
SUBNET_RANGE_IP_START_NUM=$(( $SUBNET_NUM + $ADD_TO_RANGE_NUM1 ))
SUBNET_RANGE_IP_START=$(itoa $SUBNET_RANGE_IP_START_NUM)
printf "Subnet Range IP Start: $SUBNET_RANGE_IP_START\n"
# IP End Range: *.*.*.100
ADD_TO_RANGE_NUM2=$(atoi 0.0.0.100)
SUBNET_RANGE_IP_END_NUM=$(( $SUBNET_NUM + $ADD_TO_RANGE_NUM2 ))
SUBNET_RANGE_IP_END=$(itoa $SUBNET_RANGE_IP_END_NUM)
printf "Network Range IP End: $SUBNET_RANGE_IP_END\n"

# Static IP Start Base for Nodes in Cluster
STATIC_IP_START_BASE_NUM=$(atoi 0.0.0.10)
SUBNET_STATIC_IP_BASE_NUM=$(( $SUBNET_NUM + $STATIC_IP_START_BASE_NUM ))
printf "Subnet Staic IP Base: $SUBNET_STATIC_IP_BASE_NUM\n"

# Node1 Static IP
NODE1_OFFSET=$(atoi 0.0.0.1)
NODE1_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE1_OFFSET ))
NODE1_IP=$(itoa $NODE1_IP_NUM)
printf "Static IP Node1: $NODE1_IP\n"

# Node2 Static IP
NODE2_OFFSET=$(atoi 0.0.0.2)
NODE2_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE2_OFFSET ))
NODE2_IP=$(itoa $NODE2_IP_NUM)
printf "Static IP Node2: $NODE2_IP\n"

# Node3 Static IP
NODE3_OFFSET=$(atoi 0.0.0.3)
NODE3_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE3_OFFSET ))
NODE3_IP=$(itoa $NODE3_IP_NUM)
printf "Static IP Node3: $NODE3_IP\n"

# Node4 Static IP
NODE4_OFFSET=$(atoi 0.0.0.4)
NODE4_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE4_OFFSET ))
NODE4_IP=$(itoa $NODE4_IP_NUM)
printf "Static IP Node4: $NODE4_IP\n"

# Node5 Static IP
NODE5_OFFSET=$(atoi 0.0.0.5)
NODE5_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE5_OFFSET ))
NODE5_IP=$(itoa $NODE5_IP_NUM)
printf "Static IP Node5: $NODE5_IP\n"

# Node6 Static IP
NODE6_OFFSET=$(atoi 0.0.0.6)
NODE6_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE6_OFFSET ))
NODE6_IP=$(itoa $NODE6_IP_NUM)
printf "Static IP Node6: $NODE6_IP\n"

# Node7 Static IP
NODE7_OFFSET=$(atoi 0.0.0.7)
NODE7_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE7_OFFSET ))
NODE7_IP=$(itoa $NODE7_IP_NUM)
printf "Static IP Node7: $NODE7_IP\n"

# Node8 Static IP
NODE8_OFFSET=$(atoi 0.0.0.8)
NODE8_IP_NUM=$(( $SUBNET_STATIC_IP_BASE_NUM + $NODE8_OFFSET ))
NODE8_IP=$(itoa $NODE8_IP_NUM)
printf "Static IP Node8: $NODE8_IP\n"

# IT Provided, IP Range Allocation for nodes in cluster:
# 10.1.1.0/24 = 10.1.1.0 - 10.1.1.255
node_ip=(
$NODE1_IP # node1 - 10.1.1.11
$NODE2_IP # node2 - 10.1.1.12
$NODE3_IP # node3 - 10.1.1.13
$NODE4_IP # node4 - 10.1.1.14
$NODE5_IP # node5 - 10.1.1.15
$NODE6_IP # node6 - 10.1.1.16
$NODE7_IP # node7 - 10.1.1.17
$NODE8_IP # node8 - 10.1.1.18
)

# Node Sandbox Hostnames
node_sb=(
"node1-sb.hortonworks.com"
"node2-sb.hortonworks.com"
"node3-sb.hortonworks.com"
"node4-sb.hortonworks.com"
"node5-sb.hortonworks.com"
"node6-sb.hortonworks.com"
"node7-sb.hortonworks.com"
"node8-sb.hortonworks.com"
)

# Minnowboard Hardware Address (Usually called MAC address)
minnowboard_mac=(
00:08:A2:09:EF:88
00:08:A2:09:EF:AB
00:08:A2:09:BE:EA
00:08:A2:09:F0:62
00:08:A2:09:BD:E3
00:08:A2:09:EF:92
00:08:A2:09:F2:62
00:08:A2:09:BE:F2
)

# Helper Packages for setting up PXE Server
yum install -y wget git net-tools

# 1. Configure HTTP Network Server to Export Installation Tree (ISO image)
printf "Configure HTTP Network Server to Export Installation ISO image\n"
yum install -y httpd
# Copy full CentOS7 binary DVD ISO image to HTTP server
wget http://repo1.dal.innoscale.net/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso -O ~/CentOS-7-x86_64-Minimal-1804.iso
# Mount binary DVD ISO image using mount to a suitable directory
# Suitable directory: /mnt/centos7-install/
mkdir -p /mnt/centos7-install/
# Mount the CentOS7 ISO image using the loop device to /mnt/centos7-install/
mount -o loop,ro -t iso9660 ~/CentOS-7-x86_64-Minimal-1804.iso /mnt/centos7-install/
# Copy files from mounted image to HTTP server
cp -r /mnt/centos7-install/ /var/www/html/
# Start httpd service
# Enable httpd service, so by default it starts on startup
systemctl enable httpd.service
# Start httpd service
systemctl start httpd.service
# Open HTTP Firewall Port 80 to make sure the firewall allows the server
# you are installing to access the remote installation source
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# 2. Configure a TFTP and DHCP Servers for Network Booting UEFI-based Clients
printf "Configure TFTP and DHCP Servers for Network Booting UEFI-based Clients\n"
yum install -y tftp-server tftp xinetd
# Allow incoming connections to the TFTP service in the firewall
firewall-cmd --permanent --add-service=tftp
firewall-cmd --reload

# Configure your DHCP server to use EFI boot images packaged with shim
yum install -y dhcp

# Create a backup of dhcpd.conf -> dhcpd.conf.bak
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak

# Update dhcpd.conf, so DHCP Server will know which IP addresses to
# assign to particular MAC addresses
tee -a /etc/dhcp/dhcpd.conf << EOF
allow booting;
allow bootp;
authoritative;
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
subnet $SUBNET_IP netmask $SUBNETMASK {

  option routers $GATEWAY_ROUTER_IP;
  # Dynamic Pool Range: *.*.*.20 to *.*.*.100, * is specific number
  pool {
      range $SUBNET_RANGE_IP_START $SUBNET_RANGE_IP_END;
  }
  class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
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

host node1-sb {
    option host-name ${node_sb[0]};
    hardware ethernet ${minnowboard_mac[0]};
    fixed-address ${node_ip[0]};
}
host node2-sb {
    option host-name ${node_sb[1]};
    hardware ethernet ${minnowboard_mac[1]};
    fixed-address ${node_ip[1]};
}
host node3-sb {
    option host-name ${node_sb[2]};
    hardware ethernet ${minnowboard_mac[2]};
    fixed-address ${node_ip[2]};
}
host node4-sb {
    option host-name ${node_sb[3]};
    hardware ethernet ${minnowboard_mac[3]};
    fixed-address ${node_ip[3]};
}
host node5-sb {
    option host-name ${node_sb[4]};
    hardware ethernet ${minnowboard_mac[4]};
    fixed-address ${node_ip[4]};
}
host node6-sb {
    option host-name ${node_sb[5]};
    hardware ethernet ${minnowboard_mac[5]};
    fixed-address ${node_ip[5]};
}
host node7-sb {
    option host-name ${node_sb[6]};
    hardware ethernet ${minnowboard_mac[6]};
    fixed-address ${node_ip[6]};
}
host node8-sb {
    option host-name ${node_sb[7]};
    hardware ethernet ${minnowboard_mac[7]};
    fixed-address ${node_ip[7]};
}
EOF

# Need shim.efi file from shim package and grubx64.efi file from grub2-efi
# package in ISO image file
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
# Copy EFI boot images from your directory to tftpboot
cp -r boot/efi/EFI/centos/grubx64.efi /var/lib/tftpboot/
cp -r boot/efi/EFI/centos/shim.efi /var/lib/tftpboot/
cd ~/

# Create Anaconda Kickstart for Minnowboard used in Network Installation
PASSWORD=$(python -c 'import crypt; print(crypt.crypt("hadoop", crypt.mksalt(crypt.METHOD_SHA512)))')
PSSH_PASSWD=hadoop

tee -a /var/www/html/centos7-install/ks.cfg << EOF
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use network installation
url --url="http://$IPADDRESS/centos7-install/"
# Use text install
text
# Run the Setup Agent on first boot
firstboot --enable
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

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
EOF

chmod 777 /var/www/html/centos7-install/ks.cfg

# Create grub configuration file
tee -a /var/lib/tftpboot/grub.cfg << EOF
set timeout=5
menuentry 'Install CentOS 7' {
  linuxefi images/pxeboot/vmlinuz ip=dhcp \
  inst.repo=http://$IPADDRESS/centos7-install/ \
  inst.ks=http://$IPADDRESS/centos7-install/ks.cfg
  initrdefi images/pxeboot/initrd.img
}
EOF

# Store vmlinuz and initrd.img onto tftpboot for grub configuration to access
mkdir -p /var/lib/tftpboot/images/pxeboot/
cp /var/www/html/centos7-install/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/images/pxeboot/
chmod 777 /var/lib/tftpboot/images/pxeboot/{vmlinuz,initrd.img}

# Enable your tftp server, because default is disable, and start tftp server
perl -pi -e "s/(disable)(.*=.*)(yes)/\1\2no/g" /etc/xinetd.d/tftp

# 8. Start and enable PXE Server services
# DHCPD Service:
systemctl start dhcpd
systemctl enable dhcpd
# xinetd Service that manages the TFTPD Service:
systemctl start xinetd
systemctl enable xinetd
# TFTP Server Service:
systemctl start tftp
systemctl enable tftp
