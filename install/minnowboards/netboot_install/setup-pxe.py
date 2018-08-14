#!/usr/bin/env python
import shutil
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
pxe_net_tools = netboot_tools.netHighLevelTools('minnowboard')
# Network Addresses associated with PXE Server
ip_addr = pxe_net_tools.get_ip()
interface_name = pxe_net_tools.get_net_inter_card()
subnetmask = pxe_net_tools.get_subnetmask()
broadcast = pxe_net_tools.get_broadcast()
gateway_router_ip = pxe_net_tools.get_gateway()
subnet_ip = pxe_net_tools.get_subnet()
# Set Subnet IP Range for Dynamic Allocation for Random IoT Devices connecting to Minnowboard CentOS Cluster
print "Setting the Subnet Dynamic IP Range when IoT Devices connect to Minnowboard Cluster\n"
iot_start_ip_range = pxe_net_tools.set_ip_within_subnet(subnet_ip, 0.0.0.50)
iot_end_ip_range = pxe_net_tools.set_ip_within_subnet(subnet_ip, 0.0.0.100)
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
    node_ip.append(pxe_net_tools.set_ip_within_subnet(subnet_ip, node_static_ip))

print "Configuring HTTP Server to Export Installation ISO Image\n"
centos7_src_url = 'http://ftp.usf.edu/pub/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso'
centos7_iso_path = '/root/CentOS-7-x86_64-Minimal-1804.iso'
pxe_net_tools.download_file(centos7_src_url, centos7_iso_path)
pxe_fs_tools = netboot_tools.fsTools()
centos7_iso_mnt = '/mnt/centos7-install/'
pxe_fs_tools.create_directory(centos7_mnt_path)
pxe_fs_tools.mount_directory(centos7_iso_path, centos7_iso_mnt)
# Copy files over to destination recursively
http_server_path = '/var/www/html/'
shutil.copytree(centos7_iso_mnt, http_server_path)
centos_to_http_path = '/var/www/html/centos7-install/'
pxe_fs_tools.ca_permissions('777', centos_to_http_path)
# Enable HTTPD Service to start on bootup
pxe_fs_tools.enable_systemd_service('httpd.service')
# Start HTTPD Service now
pxe_fs_tools.start_systemd_service('httpd.service')
# Add HTTP service to firewall to allow for HTTP web traffic on port 80, then reload new rule
    # Connecting to the System Bus Daemon
    # On MAC, I need to do 'brew install dbus', comes default on linux centos7
bus = dbus.SystemBus()
    # Start working with object in another application: Needed are
    # 'bus name': identifies which application you want to communicate with,
        # which is a dot separated string with a reversed domain name
    # 'object path': applications can export objects
    # What we can do with remote objects is call their methods
    # To interact with objects, we need to use a proxy object,
    # to obtain proxy we call 'get_object' method
    # The proxy acts as the 'stand-in' for the remote object
firewalld1_cmd = bus.get_object('org.fedoraproject.FirewallD1', '/org/fedoraproject/FirewallD1')
# Creating proxy to access remote object interface for permanent zone config
firewalld1_cmd_perm_zone_iface = dbus.Interface(firewalld1_cmd, 'org.fedoraproject.FirewallD1.config.zone')
firewalld1_cmd_zone_iface = dbus.Interface(firewalld1_cmd, 'org.fedoraproject.FirewallD1.zone')
firewalld1_cmd_iface = dbus.Interface(firewalld1, 'org.fedoraproject.FirewallD1')
firewalld1_cmd_iface.listServices()
firewalld1_cmd_perm_zone_iface.addService('http')
# Reload firewall rules and keep state information
firewalld1_cmd_iface.reload()
# Get list of supported Services in runtime
#pxe_net_tools.add_service_to_firewall('http')
# pxe_net_tools.reload_firewall()

# Modify Shellinabox config file to have PXE server IP
sh_box_file = '/etc/sysconfig/shellinaboxd'
regex_pattern = [r'#[ ]*OPTS=\"-t', r'host.*[^\"]']
repl = ['OPTS=\"-t', ip_addr]
for regp, r in zip(regex_pattern, repl):
    pxe_fs_tools.repl_file_string(regp, r, sh_box_file)
# Enable Shellinabox Service to start on bootup
pxe_fs_tools.enable_systemd_service('shellinaboxd.service')
pxe_fs_tools.start_systemd_service('shellinaboxd.service')
# Shellinaboxd runs on port 4200 and uses protocol tcp
firewalld1_cmd_zone_iface.getActiveZones()
firewalld1_cmd_perm_zone_iface.addPort('4200', 'tcp')
firewalld1_cmd_iface.reload()

# pxe_net_tools.get_firewall_active_zones()
# pxe_net_tools.add_port_to_firewall('4200', 'tcp', 'public')
# pxe_net_tools.reload_firewall()
