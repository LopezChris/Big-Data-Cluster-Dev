#!/bin/bash

# After Reboot once NetBoot Finished, run this script to install Ambari
NODE1_IP=10.1.1.21
PSSH_PASSWD=hadoop

# Verify on Ambari Node(node1-sb)
CHECK_IP=$(hostname -I | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo "CHECK_IP = $CHECK_IP"
# Verify on node1-sb, if so, then install pssh
case "$CHECK_IP" in
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
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "mkdir ~/.ssh"

    # Copy and Send id_rsa.pub and authorized_keys files to each host
    # Reference: https://www.tecmint.com/copy-files-to-multiple-linux-servers/
    printf "Copy and Send id_rsa.pub and authorized_keys files to each host\n"
    sshpass -p "$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av ~/.ssh/id_rsa.pub ~/.ssh/
    sshpass -p "$PSSH_PASSWD" pscp.pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -Av ~/.ssh/authorized_keys ~/.ssh/

    printf "Set permissions ~/.ssh and authorized_keys on each host\n"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 700 ~/.ssh/"
    sshpass -p "$PSSH_PASSWD" pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -A -i "chmod 600 ~/.ssh/authorized_keys"

    # Done setting password-less SSH
    printf "Done Setting Up Password-less SSH for Ambari to later install HDP....\n"

    printf "3: Enable NTP on each node in Cluster and Browser Host\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "systemctl enable ntpd"

    printf "Enable CHRONY on each node in Cluster and Browser Host\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "systemctl start chronyd"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "systemctl enable chronyd"

    printf "4: Disable iptables on each host for Ambari to communicate with them\n"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "systemctl disable firewalld"
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "service firewalld stop"

    printf "5: Disable SELinux and PackageKit\n"
    # Temporarily disable SELinux
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "setenforce 0"
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
    pssh -h /etc/pssh-hosts -l root -x "-o StrictHostKeyChecking=no" -i "umask 0022"

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
    REPO_CONFIG=$(yum repolist)

    # Verify ambari is apart of the repolist before installing ambari-server
    HAS_AMBARI_REPO=$(echo $REPO_CONFIG | grep -oE '(^| )ambari-2.7.[0-9].[0-9]( |$)' | awk 'FNR == 1 {print $1}')
    if [ "$HAS_AMBARI_REPO" = "ambari-2.7.0.0" ]; then
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
  *)
    printf "Not on Ambari Node(node1-sb)\n"
    ;;
esac
