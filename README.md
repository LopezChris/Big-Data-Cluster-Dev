# Multi-Node-HDP-Cluster-Install

Multi Node HDP Cluster Install on CentOS7

Initially your CentOS7 PXE Server VM will not have internet access, so we will need to attach a USB to the VM that has the scripts from github for setting up an internet connection and PXE Server application.

Go into Guest VM VirtualBox settings, ports, USB, then make sure Enable USB Controller is checked, USB2.0 (EHCI) Controller and USB filter for your USB are selected.

~~~bash
mkdir -p /mnt/usb-pxe-scripts/
mount -t vfat /dev/sdb1 /mnt/usb-pxe-scripts
cd /mnt/usb-pxe-scripts/Multi-Node-HDP-Cluster-Install
~~~


Set Up PXE Server on VirtualBox CentOS7 Guest VM connected by ethernet in the same network as your nodes that will be used in the HDP Cluster.
