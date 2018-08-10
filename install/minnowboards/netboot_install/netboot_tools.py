#!/usr/bin/env python
import re
import socket
import struct
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


class pxeTools:
    def __init__(self, server_name=None, deploy=None):
        self.name = name
        self.deploy = deploy

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
        return subprocess.call("ls /sys/class/net/ | grep \"en.*\"", shell=True)

    def get_subnetmask():
        """Find Subnetmask"""
