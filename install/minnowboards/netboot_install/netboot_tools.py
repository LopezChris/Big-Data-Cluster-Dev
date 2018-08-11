#!/usr/bin/env python
import re
import socket
import struct
import platform
import subprocess

# Net Boot Server Tools

class fileTools:
    def __init__(self, filename=None):
        self.filename = filename

    def repl_file_string(self, regex_string, repl):
        """Search and replace all occurrences of string in a file via regex"""
        file = open(self.filename, "r+")
        file_content = file.read()
        file.seek(0)
        file.write(re.sub(regex_string, repl, file_content))
        file.truncate()
        file.close()

    def append_if_no_match(self, regex_pattern, property, value):
        """If there's no match for regex, then appends key=value to file"""
        file = open(self.filename, "a+")
        file_content = file.read()
        match = re.match(regex_pattern, file_content)
        if match is None:
            file.write(str(property + value + "\n"))
        file.close()


class pxeNetTools:
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
