#!/bin/bash

# Tested on CentOS7 Guest VM VirtualBox

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

##
# PXE Boot Server on RHEL7/CentOS7
# Video Tutorial Reference1 : https://www.youtube.com/watch?v=BKrbshEzKfE
# Video Tutorial Reference2 : https://www.youtube.com/watch?v=UT2cGYkHJXc
##

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


# *I will have users at the beganning before running script,
# specify in settings the CentOS7 ISO image they want to use,
# which inserts the RHEL7 DVD into DVD ROM, so then the mount command will work

# installing required packages
yum install -y git vim net-tools wget


# Redhat Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s1-networkscripts-interfaces

# 1st: Set the Static IP address

# Example from video tutorial
## vim /etc/sysconfig/network-scripts/ifcfg-eth0
## BOOTPROTO=static
## IPADDR=192.168.0.254
## NETMASK=255.255.255.0
## GATEWAY=192.168.0.254
## DNS1=192.168.0.254

# My Example after using the following commands
## vim /etc/sysconfig/network-scripts/ifcfg-enp0s3
# IPADDR="10.11.6.78"
# NETMASK="255.255.248.0"
# GATEWAY="10.11.0.1"
# DNS1="10.10.1.20"


# Find Interface Name,
# kernel lists them by name, we want the one related to ethernet
# Reference: https://unix.stackexchange.com/questions/125400/how-can-i-find-available-network-interfaces
INTERFACE_NAME=$(ls /sys/class/net/ | grep -o "en.*")

# request password
# vim /etc/sysconfig/network-scripts/ifcfg-$INTERFACE_NAME
# Update ifcfg-en* with following content
# Reference on sed: https://tecadmin.net/example-of-find-and-replace-string-in-files-with-sed/


# Edit Ethernet Interface File "ifcfg-enp0s
# Replace "BOOTPROTO={and-string} with BOOTPROTO="static"
#sed -i 's/BOOTPROTO=.*/BOOTPROTO="static"/g' /etc/sysconfig/network-scripts/ifcfg-$INTERFACE_NAME

# Find IP Address of Server
IPADDRESS=$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')


# Find Subnetmask
# Reference to find SUBNETMASK: https://www.cyberciti.biz/faq/howto-find-subnet-mask-on-unix/
# Reference on awk: https://stackoverflow.com/questions/1506521/select-row-and-element-in-awk
SUBNETMASK=$(ifconfig $INTERFACE_NAME | awk 'FNR == 2 {print $4}')

# Find Default Gateway IP in Linux (Unix/FreeBSD/OpenBSD/macOS)
# Gateway - network point acts as entrance to another network
# - associated with both router, knows where to direct packet of data
#                    and a switch, fernishes actual path in/out of gateway for given packet
# Gateway nodes - control traffic within company network or at local ISP
# Gateway node in network for enterprise is acting as Proxy server and a firewall server
# Reference: https://www.cyberciti.biz/faq/how-to-find-gateway-ip-address/
GATEWAY_ROUTER_IP=$(netstat -r -n | awk 'FNR == 3 {print $2}')

# Find DNS1 Server IP Address being used
# Reference: https://unix.stackexchange.com/questions/28941/what-dns-servers-am-i-using
DNS1_IP=$(nmcli dev show | grep "DNS\[1\]" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

# Make backup of ifcfg-enp0s3
cp /etc/sysconfig/network-scripts/ifcfg-$INTERFACE_NAME /etc/sysconfig/network-scripts/ifcfg-$INTERFACE_NAME.bak

# Append IPADDR, NETMASK, GATEWAY
# Reference: https://en.wikipedia.org/wiki/Tee_(command)
# Reference: https://stackoverflow.com/questions/17701989/how-do-i-append-text-to-a-file
tee -a /etc/sysconfig/network-scripts/ifcfg-$INTERFACE_NAME << EOF
IPADDR="$IPADDRESS"
NETMASK="$SUBNETMASK"
GATEWAY="$GATEWAY_ROUTER_IP"
DNS1="$DNS1_IP"
EOF
# Saved interface configuration file with changes made
# Set hostname
hostnamectl set-hostname pxe-sb.hortonworks.com
# edit network file
tee -a /etc/sysconfig/network << EOF
NETWORKING=yes
HOSTNAME=pxe-sb.hortonworks.com
EOF

# edit /etc/hosts file
tee -a /etc/hosts << EOF
$IPADDRESS  pxe-sb.hortonworks.com
EOF

# Check NetworkManager status, if active then restart for changes to take effect
NET_MANAGER_RUNNING=$(service NetworkManager status | grep "Active:" | grep -o "running")
if [ "$NET_MANAGER_RUNNING" = "running" ]; then
    echo "NetworkManager is running, going to restart it..."
    service network restart
else
    echo "NetworkManager is inactive..."
fi;

# 2nd: Insert RHEL7 DVD in DVD ROM and mount it
# Prerequisite is that user already inserted ISO image for VM to detect if run on VM
# mount /dev/sr0 /mnt/
yum install -y vsftpd* createrepo
systemctl enable vsftpd.service
systemctl start vsftpd.service
systemctl status vsftpd.service

# Disable iptables
yum install -y iptables-services
systemctl status iptables
systemctl stop iptables

chkconfig iptables off

# Check if the SELinux policy is enforced
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security-enhanced_linux/sect-security-enhanced_linux-enabling_and_disabling_selinux-disabling_selinux
SEL_ENFORCED=$(getenforce)
# If SELinux policy is enforced, temporarily put it into permissive mode
if [ "$SEL_ENFORCED" = "Enforcing" ]; then
  echo "SELinux Policy is enforced, temporarily setting it to permissive..."
  setenforce 0
else
  echo "SELinux Policy isn't enforced"
fi;

# Check if SELinux policy is permissed
SEL_PERMISSIVE=$(getenforce)
if [ "$SEL_PERMISSIVE" = "Permissive" ]; then
  echo "SELinux Policy is permissive"
fi;

# Attach CentOS7 ISO to Guest VM
# Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/sect-using_the_mount_command-mounting
mount /dev/sr0 /mnt/

# Create directory to hold the CentOS7 DVD ISO File
mkdir -p /var/ftp/pub/rhel7/dvd
chmod 777 /var/ftp/pub/rhel7/dvd
chmod 777 /var/ftp/pub/

# Copy over all files from mount directory (Linux DVD) to RHEL7 DVD folder in FTP server
cp -rvf /mnt/* /var/ftp/pub/rhel7/dvd/

# Create yum.repo file for pxe server
tee -a /etc/yum.repos.d/yum.repo << EOF
[PXE]
name=PXE server
baseurl=file:///var/ftp/pub/rhel7/dvd
enabled=1
gpgcheck=0
EOF

yum clean all

# Create CentOS7 Repo for Nodes in the Cluster in /var/ftp/pub/rhel7/dvd/ folder
CENTOS_XML_REPO=$(ls -ltr | grep -o "^.*-c7-minimal-x86_64-comps.xml$" | awk {'print $9'})
cp /var/ftp/pub/rhel7/dvd/repodata/$CENTOS_XML_REPO /var/ftp/pub/rhel7/dvd/groups-comps-server.xml
createrepo -vg /var/ftp/pub/rhel7/dvd/groups-comps-server.xml /var/ftp/pub/rhel7/dvd/

yum list all
yum grouplist

# 3rd: Install HTTPD, and kickstart, packages using yum server
yum install -y httpd* system-config-kickstart
systemctl enable httpd.service
systemctl start httpd.service
systemctl status httpd.service
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Now create a soft link of /var/ftp/pub/ into /var/www/html/ directory, so
# you can access this repository and installation tree using FTP and HTTP protocol
ln -s /var/ftp/pub/ /var/www/html/

HTML_SOFT_LINK=$(ls -l /var/www/html/ | grep -o "pub.*")
# Check if Soft Link was created successfully
if [ "$HTML_SOFT_LINK" = "pub -> /var/ftp/pub/" ]; then
  echo "INFO: FTP Soft Links into HTTP: $HTML_SOFT_LINK"
else
  echo "ERROR: FTP Soft Link Failed to link into HTTP: $HTML_SOFT_LINK"
fi;

# Restart vsftpd
service vsftpd restart
# Forwards request to vsftpd, also shows there has been a symlink created.
chkconfig vsftpd on
# Restart httpd
service httpd restart
# Forwards request to httpd, also shows there has been a symlink created.
chkconfig httpd on

# Fix SELinux security context by using 'restorecon' command
restorecon -R /var/www/html/
restorecon -R /var/ftp/pub/

# Restart services 'vsftpd' and 'httpd'
service vsftpd restart
chkconfig vsftpd on
service httpd restart
chkconfig httpd on

# Use kickstart file from Manual Install of CentOS7 on Minnowboard Turbot
# and save into /var/ftp/pub/ with name of m-turbot-ks.cfg
cp m-turbot-ks.cfg /var/ftp/pub/m-turbot-ks.cfg
ls -l /var/ftp/pub/
chmod 777 /var/ftp/pub/m-turbot-ks.cfg
chmod 777 /var/www/html/pub/m-turbot-ks.cfg
# Restart vsftpd
service vsftpd restart
# Restart httpd
service httpd restart

# 5th: Install syslinux, xinetd, tftp-server, dhcp using yum
yum install -y dhcp tftp tftp-server syslinux xinetd
systemctl enable dhcpd.service
systemctl start dhcpd.service
systemctl status dhcpd.service
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --reload

systemctl enable tftpd.service
systemctl start tftpd.service
systemctl status tftpd.service
firewall-cmd --permanent --add-service=tftp
firewall-cmd --reload

systemctl enable xinetd.service
systemctl start xinetd.service
systemctl status xinetd.service

# Create pxelinux.cfg
mkdir /var/lib/tftpboot/pxelinux.cfg

# Copy pxelinux.0 file from /usr/share/syslinux/pxelinux.0 to /var/lib/tftpboot/ directory
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# Enable your tftp server, because default is disable, and start tftp server
# vim /etc/xinetd.d/tftp
# Disable=no
perl -pi -e "s/(disable)(.*=.*)(yes)/\1\2no/g" /etc/xinetd.d/tftp
service xinetd restart
chkconfig xinetd on

# 6th: Configure DHCP
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
rm -rf /etc/dhcp/dhcpd.conf
# Edit dhcpd.conf file according to your network

# vim /etc/dhcp/dhcpd.conf
# https://en.wikipedia.org/wiki/Subnetwork
# To get subnet or network-prefix, AND "IP address" with "subnet mask"
# Convert IP Address and SubnetMask to Decimal
IPADDRESS_NUM=$(atoi $IPADDRESS)
SUBNETMASK_NUM=$(atoi $SUBNETMASK)
# Perform Bitwise AND on IPAddress and SubnetMask
# to get Network IP Address in Decimal
NETWORK_NUM=$(( $IPADDRESS_NUM & $SUBNETMASK_NUM ))
# Convert Decimal to IP for Network IP
NETWORK_IP=$(itoa $NETWORK_NUM)
# Get Network Range
# Add 10 IPs to the range
ADD_TO_RANGE_NUM=$(atoi 0.0.0.10)
NETWORK_RANGE_NUM=$(( $NETWORK_NUM | $ADD_TO_RANGE_NUM ))
NETWORK_RANGE_IP=$(itoa $NETWORK_RANGE_NUM)
# Create and Configure new DHCP Config File
printf "Config DHCP Server...\n"
tee -a /etc/dhcp/dhcpd.conf << EOF
allow booting;
allow bootp;
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

subnet $NETWORK_IP_ID netmask $SUBNETMASK {
    option routers $IPADDRESS;
    range $NETWORK_RANGE_IP_START $NETWORK_RANGE_IP_END;

    next-server $IPADDRESS;
    filename "pxelinux/bootx64.efi";

    host node1-sb {
        option host-name "node1-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:EF:88;
        fixed-address $STATIC_IP_NODE1;
    }
    host node2-sb {
        option host-name "node2-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:EF:AB;
        fixed-address $STATIC_IP_NODE2;
    }
    host node3-sb {
        option host-name "node3-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:BE:EA;
        fixed-address $STATIC_IP_NODE3;
    }
    host node4-sb {
        option host-name "node4-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:F0:62;
        fixed-address $STATIC_IP_NODE4;
    }
    host node5-sb {
        option host-name "node5-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:BD:E3;
        fixed-address $STATIC_IP_NODE5;
    }
    host node6-sb {
        option host-name "node6-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:EF:92;
        fixed-address $STATIC_IP_NODE6;
    }
    host node7-sb {
        option host-name "node7-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:F2:62;
        fixed-address $STATIC_IP_NODE7;
    }
    host node8-sb {
        option host-name "node8-sb.hortonworks.com"
        hardware ethernet 00:08:A2:09:BE:F2;
        fixed-address $STATIC_IP_NODE8;
    }
}
EOF

service dhcpd restart
chkconfig dhcpd on

#tail -f /var/log/messages

service dhcpd status

# 7th: Copy following files from CentOS7 DVD into /var/lib/tftpboot
cd /var/ftp/pub/rhel7/dvd/images/pxeboot/
ls -l
cp /var/lib/tftpboot/initrd.img /var/lib/tftpboot/initrd.img.bak
cp /var/lib/tftpboot/vmlinuz /var/lib/tftpboot/vmlinuz.bak
yes | cp initrd.img vmlinuz /var/lib/tftpboot
cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/

cd /var/ftp/pub/rhel7/dvd/isolinux/
yes | cp -rvf * /var/lib/tftpboot/

# Need to create a boot menu
# vim /var/lib/tftpboot/pxelinux.cfg/default
tee -a /var/lib/tftpboot/pxelinux.cfg/default << EOF
default vesamenu.c32
#prompt 1
timeout 600
display boot.msg
menu background splash.jpg
menu title Welcome to the CentOS7 PXE Installation!
label local
menu label boot from ^local drive
menu default
localboot 0xffff

label ws
menu label Unattended Installation of CentOS7
kernel vmlinuz
append biosdevname=0 ksdevice=link load_ramdisk=1 initrd=initrd.img linux network ks=http://$IPADDRESS/pub/m-turbot-ks.cfg noipv6

label si
menu label CentOS7 Standard Installation
kernel vmlinuz
append biosdevname=0 ksdevice=link load_ramdisk=1 initrd=initrd.img
EOF

# tail -f /var/log/messages

iptables -t filter -F
service iptables save
service iptables stop

service vsftpd restart
chkconfig vsftpd on
service dhcpd restart
chkconfig dhcpd on
service xinetd restart
chkconfig xinetd on
