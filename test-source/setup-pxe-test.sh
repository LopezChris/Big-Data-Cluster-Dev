#!/bin/bash

##
# Setup PXE Server For CentOS7 Network Installation
#
# Preferred: Tested on port 1.089.1 (WORKS) private network and used IP range
# and Gateway provided by IT. My nodes have access over the internet too.
#
# Backup Plan: Tested on port 1.089.2 (WORKS) without IP range and Gateway provided by IT
# My nodes have access to the internet.
#
##

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

# Helper Packages for setting up PXE Server
yum install -y epel-release
yum install -y wget
yum install -y perl
yum install -y git
yum install -y net-tools
yum install -y openssl
yum install -y shellinabox

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
printf "Subnet Staic IP Base: $SUBNET_STATIC_IP_BASE\n"

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

# Static IPs that'll be used for nodes
node_ip=(
$NODE1_IP # node1
$NODE2_IP # node2
$NODE3_IP # node3
$NODE4_IP # node4
$NODE5_IP # node5
$NODE6_IP # node6
$NODE7_IP # node7
$NODE8_IP # node8
)

# Node Sandbox Hostnames
node_sb=(
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

# 1. Configure HTTP Network Server to Export Installation Tree (ISO image)
printf "Configure HTTP Network Server to Export Installation ISO image\n"
yum install -y httpd
# Copy full CentOS7 binary DVD ISO image to HTTP server
wget http://mirror.rackspace.com/CentOS/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso -O ~/CentOS-7-x86_64-Minimal-1804.iso
# Mount binary DVD ISO image using mount to a suitable directory
# Suitable directory: /mnt/centos7-install/
mkdir -p /mnt/centos7-install/
# Mount the CentOS7 ISO image using the loop device to /mnt/centos7-install/
mount -o loop,ro -t iso9660 ~/CentOS-7-x86_64-Minimal-1804.iso /mnt/centos7-install/
# Copy files from mounted image to HTTP server
cp -r /mnt/centos7-install/ /var/www/html/
chmod 777 /var/www/html/centos7-install/
# Start httpd service
# Enable httpd service, so by default it starts on startup
systemctl enable httpd.service
# Start httpd service
systemctl start httpd.service
# Open HTTP Firewall Port 80 to make sure the firewall allows the server
# you are installing to access the remote installation source
firewall-cmd --permanent --add-service=http
firewall-cmd --reload


# Extra: Configure Shellinabox
# PORT should be 4200
# IP address should be PXE server IP
# Restrict access to shellinabox to localhost only? probably not
perl -pi -e "s/#[ ]*OPTS=\"-t/OPTS=\"-t/g" /etc/sysconfig/shellinaboxd
perl -pi -e "s/host.*[^\"]/$IPADDRESS\"/g" /etc/sysconfig/shellinaboxd
# Need to uncomment the line

# Start
systemctl enable shellinaboxd.service
systemctl start shellinaboxd.service
# Verify
netstat -nap | grep shellinabox
# Open shellinabox port 4200, make sure firewall
# allows incoming connections to the shellinaboxd service
# Check firewall active zone:
firewall-cmd --get-active-zones
firewall-cmd --zone=public --add-port=4200/tcp --permanent
firewall-cmd --reload


# 2. Configure a TFTP and DHCP Servers for Network Booting UEFI-based Clients
printf "Configure TFTP and DHCP Servers for Network Booting UEFI-based Clients\n"
yum install -y tftp-server
yum install -y tftp
yum install -y xinetd
# Allow incoming connections to the TFTP service in the firewall
firewall-cmd --permanent --add-service=tftp
firewall-cmd --reload

# Configure your DHCP server to use EFI boot images packaged with shim
yum install -y dhcp

# Create a backup of dhcpd.conf -> dhcpd.conf.bak
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak

# Update dhcpd.conf, so DHCP Server will know which IP addresses to
# assign to particular MAC addresses
# https://www.pks.mpg.de/~mueller/docs/suse10.1/suselinux-manual_en/manual/sec.dhcp.server.html
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
  option broadcast-address $BROADCAST;
  option routers $GATEWAY_ROUTER_IP;
  # Public DNS Server List: https://public-dns.info/nameserver/us.html
  option domain-name-servers 8.8.8.8, 104.155.28.90, 216.116.96.2;
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

# Request DHCP Server to give each client an IP addr based on ethernet addr
host node1-sb {
    option host-name "${node_sb[0]}";
    hardware ethernet ${minnowboard_mac[0]};
    fixed-address ${node_ip[0]};
}
host node2-sb {
    option host-name "${node_sb[1]}";
    hardware ethernet ${minnowboard_mac[1]};
    fixed-address ${node_ip[1]};
}
host node3-sb {
    option host-name "${node_sb[2]}";
    hardware ethernet ${minnowboard_mac[2]};
    fixed-address ${node_ip[2]};
}
host node4-sb {
    option host-name "${node_sb[3]}";
    hardware ethernet ${minnowboard_mac[3]};
    fixed-address ${node_ip[3]};
}
host node5-sb {
    option host-name "${node_sb[4]}";
    hardware ethernet ${minnowboard_mac[4]};
    fixed-address ${node_ip[4]};
}
host node6-sb {
    option host-name "${node_sb[5]}";
    hardware ethernet ${minnowboard_mac[5]};
    fixed-address ${node_ip[5]};
}
host node7-sb {
    option host-name "${node_sb[6]}";
    hardware ethernet ${minnowboard_mac[6]};
    fixed-address ${node_ip[6]};
}
host node8-sb {
    option host-name "${node_sb[7]}";
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
cp -r boot/efi/EFI/centos/shimx64.efi /var/lib/tftpboot/
cp -r boot/efi/EFI/centos/shim.efi /var/lib/tftpboot/
chmod 777 /var/lib/tftpboot/grubx64.efi
chmod 777 /var/lib/tftpboot/shimx64.efi
chmod 777 /var/lib/tftpboot/shim.efi
cd ~/

# Create Anaconda Kickstart for Minnowboard used in Network Installation
PASSWORD=$(python -c 'import crypt; print(crypt.crypt("hadoop", crypt.mksalt(crypt.METHOD_SHA512)))')

# ks.cfg contains configuration for installing CentOS7
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

# Add CentOS7 OS (includes ntp, chrony, wget, net-tools) Repository
repo --name=os --baseurl=http://mirror.centos.org/centos/7/os/x86_64/

# Add EPEL (includes pssh, epel) Repository
repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

%packages

@^minimal
@core
kexec-tools
pssh
sshpass
perl
git
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

# Reboot after installation is complete
reboot
EOF

# Create a setup-ambari-test.sh script that will be stored on the HTTP server of PXE
# for node1-sb client to download
tee -a /var/www/html/centos7-install/scripts/setup-ambari.sh << EOF
#!/bin/bash

# After Reboot once NetBoot Finished, run this script to install Ambari
PSSH_PASSWD=hadoop

# Verify on Ambari Node(node1-sb)
CHECK_IP=\$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo "CHECK_IP = \$CHECK_IP"
# Verify on node1-sb, if so, then install pssh
case "\$CHECK_IP" in
  "$NODE1_IP")

    printf "2. Setting up Password-less SSH on Each Host\n"
    # Run shell script on each host ip address provided in pssh-hosts file
    # Appends map of ip to host on each node's hosts file

    printf "Creating public and private SSH keys on Ambari Server Host\n"
    # Reference: https://stackoverflow.com/questions/10767488/automate-ssh-keygen-t-rsa-so-it-does-not-ask-for-a-passphrase
    ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''
    # Add SSH Public Key to Authorized_keys file to each target host
    printf "Copy SSH Public Key into 'authorized_keys' file\n"
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

    # Create ~/.ssh folder on each host
    printf "Create ~/.ssh folder on each host\n"
    sshpass -p "\$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "mkdir ~/.ssh"

    # Copy and Send id_rsa.pub and authorized_keys files to each host
    # Reference: https://www.tecmint.com/copy-files-to-multiple-linux-servers/
    printf "Copy and Send id_rsa.pub and authorized_keys files to each host\n"
    sshpass -p "\$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av "~/.ssh/id_rsa.pub ~/.ssh/"
    sshpass -p "\$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av "~/.ssh/authorized_keys ~/.ssh/"

    printf "Set permissions ~/.ssh and authorized_keys on each host\n"
    sshpass -p "\$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 700 ~/.ssh"
    sshpass -p "\$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 600 ~/.ssh/authorized_keys"

    # Done setting password-less SSH
    printf "Done Setting Up Password-less SSH for Ambari to later install HDP....\n"

    printf "3: Enable NTP on each node in Cluster and Browser Host\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable ntpd"

    printf "Enable CHRONY on each node in Cluster and Browser Host\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl start chronyd"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable chronyd"

    printf "4: Disable iptables on each host for Ambari to communicate with them\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl disable firewalld"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "service firewalld stop"

    printf "5: Disable SELinux and PackageKit\n"
    # Temporarily disable SELinux
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "setenforce 0"
    # Permanently disable SELinux
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"

    # Check on install host (Ambari Server) if path to refresh-packagekit.conf
    # exists, if not, then no need to disable it
    if [ -e /etc/yum/pluginconf.d/refresh-packagekit.conf ]; then
      printf "refresh-packagekit.conf exists\n";
      DISABLED=0
      perl -pi -e "s/(enabled)(.*=.*)([0-9]+)/\1\2\$DISABLED/g" /etc/yum/pluginconf.d/refresh-packagekit.conf
    else
      printf "refresh-packagekit.conf is nonexistent\n"
    fi

    # Set umask to 022 since Ambari, HDP, HDF support that value
    printf "Set unmask to 0022 since Ambari, HDP, HDF support that value\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "umask 0022"

    # On Node1 Server Host, download Ambari Repo
    printf "6: Downloading Ambari 2.7 Repo\n"

    # Download Ambari Repo, yum install ambari-server should work cause it is local
    # 4. Place the ambari.repo file on the Ambari Server host
    wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.0.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
    # 5. Edit the priorities.conf file to add the following values
    echo "#!/bin/bash" | tee -a /edit_priorities.sh
    echo "tee -a /etc/yum/pluginconf.d/priorities.conf << EOF" | tee -a /edit_priorities.sh
    echo "[main]" | tee -a /edit_priorities.sh
    echo "enabled=1" | tee -a /edit_priorities.sh
    echo "gpgcheck=0" | tee -a /edit_priorities.sh
    echo "EOF" | tee -a /edit_priorities.sh

    bash /edit_priorities.sh

    # Confirm repository list has Ambari Repo
    REPO_CONFIG=\$(yum repolist)

    # Verify ambari is apart of the repolist before installing ambari-server
    HAS_AMBARI_REPO=\$(echo \$REPO_CONFIG | grep -oE '(^| )ambari-2.7.[0-9].[0-9]( |$)' | awk 'FNR == 1 {print $1}')
    if [ "$HAS_AMBARI_REPO" = "ambari-2.7.0.0" ]; then
      printf "7: Repo List has Ambari Repo, Installing ambari-server\n"
      yum install -y ambari-server

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
  *)
    printf "Not on Ambari Node(node1-sb)\n"
    ;;
esac
EOF


# Append kickstart post section to begin preparing the cluster environment for
# an ambari install
tee -a /var/www/html/centos7-install/ks.cfg << EOF
%post --log=~/ks.log

printf "1. Preparing Cluster Environment....\n"
# Adding static IPs and hostnames to hosts file of each node in the cluster
printf "Editing /etc/hosts file on every node in cluster\n"
printf "to contain IP address and Fully Qualified Domain Name...\n"
echo "${node_ip[0]} ${node_sb[0]}" | tee -a /etc/hosts
echo "${node_ip[1]} ${node_sb[1]}" | tee -a /etc/hosts
echo "${node_ip[2]} ${node_sb[2]}" | tee -a /etc/hosts
echo "${node_ip[3]} ${node_sb[3]}" | tee -a /etc/hosts
echo "${node_ip[4]} ${node_sb[4]}" | tee -a /etc/hosts
echo "${node_ip[5]} ${node_sb[5]}" | tee -a /etc/hosts
echo "${node_ip[6]} ${node_sb[6]}" | tee -a /etc/hosts
echo "${node_ip[7]} ${node_sb[7]}" | tee -a /etc/hosts

# Reference: https://superuser.com/questions/1163676/how-to-echo-a-line-of-bash-to-file-without-executing
CHECK_IP=\$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo "CHECK_IP = \$CHECK_IP"

# Check IP of node, then run appropriate case
case "\$CHECK_IP" in
  "${node_ip[0]}") printf "Setting up Node1-sb:\n"
    # Create pssh_hosts file

    printf "Task 2: Creating pssh-hosts file\n"
    echo "${node_ip[0]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[1]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[2]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[3]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[4]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[5]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[6]}" | tee -a /etc/pssh-hosts
    echo "${node_ip[7]}" | tee -a /etc/pssh-hosts

    wget http://$IPADDRESS/centos7-install/scripts/setup-ambari.sh -O ~/setup-ambari-test.sh

    # Set Hostname for Node1
    printf "Task 4.7: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[0]}

    printf "Task 4.8: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[0]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[1]}") printf "Setting up Node2-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[1]}
    printf "Task 2: Appending FQDN to Network Config file\n"

    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[1]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[2]}") printf "Setting up Node3-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[2]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[2]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[3]}") printf "Setting up Node4-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[3]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[3]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[4]}") printf "Setting up Node5-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[4]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[4]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[5]}") printf "Setting up Node6-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[5]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[5]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[6]}") printf "Setting up Node7-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[6]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[6]}" | tee -a /etc/sysconfig/network
  ;;
  "${node_ip[7]}") printf "Setting up Node8-sb:\n"
    printf "Task 1: Permanently set hostname\n"
    hostnamectl set-hostname ${node_sb[7]}
    printf "Task 2: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[7]}" | tee -a /etc/sysconfig/network
  ;;
  *)
    printf "Automation applies to all nodes in the cluster\n"
  ;;
esac

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

systemctl status httpd.service dhcpd xinetd tftp
