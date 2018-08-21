#!/bin/bash

# ks.cfg appending post script to install ambari
tee -a /var/www/html/centos7-install/ks.cfg << EOF
# Post Installation Script
%post --log=/root/ks.log

# Reference: https://superuser.com/questions/1163676/how-to-echo-a-line-of-bash-to-file-without-executing
CHECK_IP=\$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo "CHECK_IP = \$CHECK_IP"
# Verify on node1-sb, if so, then install pssh
case "\$CHECK_IP" in
  "${node_ip[0]}") printf "Setting up Node1-sb:\n"
    printf "1. Preparing Environment....\n"
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

    # Creating script that will be used to add hosts info to each host in cluster
    printf "Task 3: Creating shell script to append ip map host across each node\n"
    echo "#!/bin/bash" | tee -a /append_hosts.sh
    echo "cat << EOF >> /etc/hosts" | tee -a /append_hosts.sh
    echo "${node_ip[0]} ${node_sb[0]}" | tee -a /append_hosts.sh
    echo "${node_ip[1]} ${node_sb[1]}" | tee -a /append_hosts.sh
    echo "${node_ip[2]} ${node_sb[2]}" | tee -a /append_hosts.sh
    echo "${node_ip[3]} ${node_sb[3]}" | tee -a /append_hosts.sh
    echo "${node_ip[4]} ${node_sb[4]}" | tee -a /append_hosts.sh
    echo "${node_ip[5]} ${node_sb[5]}" | tee -a /append_hosts.sh
    echo "${node_ip[6]} ${node_sb[6]}" | tee -a /append_hosts.sh
    echo "${node_ip[7]} ${node_sb[7]}" | tee -a /append_hosts.sh
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
    hostnamectl set-hostname ${node_sb[0]}

    printf "Task 4.8: Appending FQDN to Network Config file\n"
    echo "NETWORKING=yes" | tee -a /etc/sysconfig/network
    echo "HOSTNAME=${node_sb[0]}" | tee -a /etc/sysconfig/network

    # Done setting password-less SSH
    printf "Task 5: Enable NTP on each node in Cluster and Browser Host\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable ntpd"

    printf "Task 5.1: Enable CHRONY on each node in Cluster and Browser Host\n"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "yum install -y chrony"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl start chronyd"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl enable chronyd"

    printf "Task 6: Disable iptables on each host for Ambari to communicate with them\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "systemctl disable firewalld"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "service firewalld stop"

    printf "Task 7: Disable SELinux and PackageKit\n"
    # pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "setenforce 0"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"

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

    #
    HAS_AMBARI_REPO=\$(echo \$REPO_CONFIG | grep -oE '(^| )ambari-2.7.[0-9].[0-9]( |$)' | awk 'FNR == 1 {print $1}')
    if [ "\$HAS_AMBARI_REPO" = "ambari-2.7.0.0" ]; then
      printf "Task 9: Repo List has Ambari Repo, Installing ambari-server\n"
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
