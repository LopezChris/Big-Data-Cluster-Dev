# Preparing for Network Installation

Initially your CentOS7 PXE Server VM will not have internet access, so we will need to attach a USB to the VM that has the scripts from github for setting up an internet connection and PXE Server application.

Go into Guest VM VirtualBox settings, ports, USB, then make sure Enable USB Controller is checked, USB2.0 (EHCI) Controller and USB filter for your USB are selected.

In your Guest VM console, enter the following commands to mount the usb-device.
Once it is mounted, we run the setup scripts.

~~~bash
mkdir -p /mnt/usb-devices/
mount -t vfat /dev/sdb1 /mnt/usb-devices/
cd /mnt/usb-devices/Multi-Node-HDP-Cluster-Install/assets/test-source
cd test-source
bash setup-pxe-internet-access.sh | tee -a setup-pxe-internet-log.txt
bash setup-pxe-test.sh | tee -a setup-pxe-log.txt
~~~

Set Up PXE Server on VirtualBox CentOS7 Guest VM connected by ethernet in the same network as your nodes that will be used in the HDP Cluster.

## Configuring Minnowboard UEFI Boot Firmware

Press the power button on the Minnowboard, once a load screen appears, press `F2`
to load the UEFI Boot Menu.

~~~bash
Go into Boot Maintenance Management -> Boot Options
-> Change Boot Order -> Change the order -> Press `Enter` -> Highlight `EFI Network* IPv4`
-> Press `Shift +` -> Press `Enter` -> Press `F10` to save.
~~~

Now you can turn the board off, the next you turn it on again, it will perform a network boot and that is where PXE Server will respond to the Minnowboard's request for installing
CentOS7. Once you have all Minnowboard's Boot Option set to `EFI Network* IPv4`, then you are ready to perform a network installation of CentOS7.

## Perform Network Install of CentOS7 with Ambari Server

With a network installation, make sure to netboot 4 minnowboards at time until all 8 or however many you have in the cluster are done with the CentOS7 installation. If you try
to install more than 4, you may notice that on some boards the installation didn't complete.
Therefore, we recommend you first install CentOS7 on 4 minnowboards.

During the installation, the CentOS7 installer references the kickstart file that
is hosted on the HTTP server. Kickstart file automates the CentOS7 installation and
instructs the installer how you want CentOS7 to be installed. Additionally, we
leverage a post section in the Kickstart file to install additional software,
setup each minnowboard (also known as a node) for password-less SSH, install
ambari-server on the master node (node1-sb.hortonworks.com) and create a custom
startup script (systemd file) for setting up ambari-server on firstboot of CentOS7
on the master node. Once the installation completes, you now have CentOS7 on
each node and ambari-server is installed and setup.

Monitor the RAM of each node in the cluster from the PXE server:

~~~bash
pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "free -m"
~~~

Free up cache and buffer to create more space in RAM:

~~~bash
pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "sync; echo 1 > /proc/sys/vm/drop_caches"
~~~

## After Network Install Completes, Start Ambari Server

Once you are done installing CentOS7 on each of your Minnowboards over the
network, you can start `ambari-server` on the master node (node1-sb.hortonworks.com)
remotely from the PXE server. Type in the following command to start `ambari-server`.

~~~bash
ssh root@node1-sb.hortonworks.com ambari-server start
~~~

## Install HDP3.0 Stack via Ambari Install Wizard

Now you can access Ambari Web UI:

~~~bash
http://node1-sb.hortonworks.com:8080
~~~

Press on `Launch Ambari Install Wizard` to begin configuring the way you want
your HDP3.0 to be installed, such as the services, the way those services are
configured and which nodes the services are installed on.
