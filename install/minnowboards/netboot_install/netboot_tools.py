#!/usr/bin/env python
import re
import os
import dbus
import socket
import struct
import urllib2
import platform
import subprocess

# Net Boot Server Tools

class fsTools:
    def __init__(self, filename=None):
        if filename is not None:
            self.filename = filename
        else:
            print 'filename not initialized\n'

    def repl_file_string(self, regex_string, repl, filename=None):
        """Search and replace all occurrences of string in a file via regex"""
        if filename is not None:
            self.filename = filename
        if self.filename is not None:
            file = open(self.filename, "r+")
            file_content = file.read()
            file.seek(0)
            file.write(re.sub(regex_string, repl, file_content))
            file.truncate()
            file.close()
        else:
            print 'Need a filename before replacing string in file\n'

    def append_if_no_match(self, regex_pattern, property, value, filename=None):
        """If there's no match for regex, then appends key=value to file"""
        if filename is not None:
            self.filename = filename
        if self.filename is not None:
            file = open(self.filename, "a+")
            file_content = file.read()
            match = re.match(regex_pattern, file_content)
            if match is None:
                file.write(str(property + value + "\n"))
            file.close()
        else:
            print 'Need a filename before appending to file on no match\n'

    def create_directory(path):
        """Create directory if path doesn't exist"""
        try:
            if not os.path.exists(path):
                os.makedirs(path)
            except OSError:
                print "Error: Creating directory path: ", path

    def mount_directory(file, mnt_dst):
        """Take the file and mount to path destination"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("mount -o loop,ro -t iso9660 " + file + " " + mnt_dst), shell=True)

    def ca_permissions(mode, path):
        """Change access permissions to file system object (file and directory)"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("chmod " + mode + " " + path), shell=True)

    def restart_systemd_service(service, mode = "replace"):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            job = manager.RestartUnit(service, mode)
            result = True
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result

    def start_systemd_service(service, mode = "replace"):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            job = manager.StartUnit(service, mode)
            result = True
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result

    def stop_systemd_service(service, mode = "replace"):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            job = manager.StopUnit(service, mode)
            result = True
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result


    def enable_systemd_service(service):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            job = manager.EnableUnitFiles([service],
                                          dbus.Boolean(False),
                                          dbus.Boolean(True))
            result = True
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result

    def disable_systemd_service(service):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            job = manager.DisableUnitFiles([service],
                                          dbus.Boolean(False))
            result = True
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result

    def get_systemd_service_state(service):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_objects('org.freedesktop.systemd1', 'org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        if manager is None:
            result = False
        try:
            state = manager.GetUnitFileState(service)
            result = state
        except dbus.exceptions.DBusException as error:
            print error
            result = False
        return result

class netHighLevelTools:
    def __init__(self, deployment=None):
        self.deployment = deployment

    def get_hostname():
        """Get Hostname of local machine"""
        try:
            host_name = socket.gethostname()
            # print "Hostname : " + host_name
            return host_name
        except:
            print "Unable to get Hostname"

    def get_ip():
        """Get IP Address of local machine"""
        try:
            host_ip = socket.gethostbyname(get_hostname())
            # print "IP : " + host_ip
            return host_ip
        except:
            print "Unable to get IP"

    def ip2num(ip):
        """Convert IP string to long integer"""
        packedIP = socket.inet_aton(ip)
        return struct.unpack("!L", packedIP)[0]

    def num2ip(num):
        """Convert long integer to IP string"""
        return socket.inet_ntoa(struct.pack("!L", num))

    def get_net_inter_card():
        """Get Network Interface (Should work on CentOS7, Ubuntu)"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                result = subprocess.check_output("ls /sys/class/net/ | grep \"en.*\"", shell=True).strip()
        return result

    def get_subnetmask():
        """Find Subnetmask"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                result = subprocess.check_output(str("ifconfig " + get_net_inter_card() + " | awk 'FNR == 2 {print $4}'"), shell=True).strip()
        return result

    def get_broadcast():
        """Get Broadcast Address"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                result = subprocess.check_output(str("ifconfig " + get_net_inter_card() + " | awk 'FNR == 2 {print $6}'"), shell=True).strip()
        return result

    def get_gateway():
        """Get Gateway Router IP Address"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                result = subprocess.check_output(str("netstat -r -n | awk 'FNR == 3 {print $2}'"), shell=True).strip()
        return result

    def get_subnet():
        """Get Subnet IP Address"""
        ipaddress_num = ip2num(get_ip())
        subnetmask_num = ip2num(get_subnetmask())
        subnet_num = ipaddress_num & subnetmask_num
        subnet_ipaddr = num2ip(subnet_num)
        return subnet_ipaddr

    def set_ip_within_subnet(subnet, ip):
        """Set the IP within the Subnet for a device"""
        subnet_num = ip2num(subnet)
        offset_num = ip2num(ip)
        ip_num_within_subnet = subnet_num + offset_num
        ip_within_subnet = num2ip(ip_num_within_subnet)
        return ip_within_subnet

    def download_file(url, dst):
        """Download file from URL and store to destination"""
        f = urllib2.urlopen(url)
        data = f.read()
        with open(dst, "wb") as url_file:
            url_file.write(data)

    def add_service_to_firewall(service):
        """Add systemd service to firewall"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("firewall-cmd --permanent --add-service=" + service), shell=True)

    def add_port_to_firewall(port, protocol, zone):
        """Opens port to firewall for zone using protocol"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("firewall-cmd --zone=" + zone + " -add-port=" + port + "/" + protocol + " --permanent"), shell=True)

    def get_firewall_active_zones():
        """Get Firewall Active Zones"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call(str("firewall-cmd --get-active-zones"), shell=True)

    def reload_firewall():
        """Reloads firewall with latest configurations"""
        for pattern in platform.linux_distribution():
            if 'CentOS' in pattern:
                subprocess.call("firewall-cmd --reload", shell=True)
