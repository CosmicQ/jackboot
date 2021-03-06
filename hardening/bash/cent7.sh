#!/bin/bash

# Simple bash script to get hardening started (CIS Level 1)

# REQUIREMENTS - Systemd

# 1.1.1.1-8 - Disable Filesystems
FILESYSTEMS=(
  cramfs
  freevxfs
  jffs2
  hfs
  hfsplus
  squashfs
  udf
  vfat
)

touch /etc/modprobe.d/CIS.conf

for FS in "${FILESYSTEMS[@]}"
do
  if ! grep $FS /etc/modprobe.d/CIS.conf; then
    echo "Disabling $FS in /etc/modprobe.d/CIS.conf.."
    echo "install $FS /bin/true" >> /etc/modprobe.d/CIS.conf
  fi
done

# 1.7.1 - Logon Banners

BANNERS=(
  "/etc/motd"
  "/etc/issue"
  "/etc/issue.net"
)

BANNER_DEFAULT="Authorized uses only. All activity may be monitored and reported.\n"
BANNER_MD5=`echo $BANNER_DEFAULT |md5`

for file in "${BANNERS}"
do
  if [ `cat $file | md5` != $BANNER_MD5 ]; then
    echo $BANNER_DEFAULT > $file
    chmod 0644 $file
  fi
done

# 3.5.1-4 - Uncommon Network Protocols
NET_PROTOCOLS=(
  dccp
  sctp
  rds
  tipc
)

touch /etc/modprobe.d/CIS.conf

for NP in "${NET_PROTOCOLS[@]}"
do
  if ! grep $NP /etc/modprobe.d/CIS.conf; then
    echo "Disabling $NP in /etc/modprobe.d/CIS.conf.."
    echo "install $NP /bin/true" >> /etc/modprobe.d/CIS.conf
  fi
done


# 1.1.3 - /tmp nodev
Edit /etc/systemd/system/local-fs.target.wants/tmp.mount to add nodev to the /tmp
mount options:
[Mount]
Options=mode=1777,strictatime,noexec,nodev,nosuid
Run the following command to remount /tmp :
# mount -o remount,nodev /tmp

# 1.1.4 - /tmp
Edit /etc/systemd/system/local-fs.target.wants/tmp.mount to add nosuid to the /tmp
mount options:
[Mount]
Options=mode=1777,strictatime,noexec,nodev,nosuid
Run the following command to remount /tmp :
# mount -o remount,nosuid /tmp

# 1.1.5 - /tmp
Edit /etc/systemd/system/local-fs.target.wants/tmp.mount to add noexec to the /tmp
mount options:
[Mount]
Options=mode=1777,strictatime,noexec,nodev,nosuid
Run the following command to remount /tmp :
# mount -o remount,noexec /tmp

# 1.1.8 - /var
Edit the /etc/fstab file and add nodev to the fourth field (mounting options) for the
/var/tmp partition. See the fstab(5) manual page for more information.
Run the following command to remount /var/tmp :
# mount -o remount,nodev /var/tmp

# 3.1 - 3.3 Network Parameters
NET_CONFIG_ZED=(
    "net.ipv4.ip_forward"
    "net.ipv4.conf.all.send_redirects"
    "net.ipv4.conf.default.send_redirects"
    "net.ipv4.conf.all.accept_source_route"
    "net.ipv4.conf.default.accept_source_route"
    "net.ipv4.conf.all.accept_redirects"
    "net.ipv4.conf.default.accept_redirects"
    "net.ipv4.conf.all.secure_redirects"
    "net.ipv4.conf.default.secure_redirects"
    "net.ipv6.conf.all.accept_ra"
    "net.ipv6.conf.default.accept_ra"
    "net.ipv6.conf.all.accept_redirects"
    "net.ipv6.conf.default.accept_redirects"
    )
NET_CONFIG_ONE=(
    "net.ipv4.conf.all.log_martians"
    "net.ipv4.conf.default.log_martians"
    "net.ipv4.icmp_echo_ignore_broadcasts"
    "net.ipv4.icmp_ignore_bogus_error_responses"
    "net.ipv4.conf.all.rp_filter"
    "net.ipv4.conf.default.rp_filter"
    "net.ipv4.tcp_syncookies"
)

function update_sysconfig() {
  num=$1 && shift
  arr=("$@")

  for element in ${arr[@]}; do
    if grep -q "^#${element}" /etc/sysctl.conf; then
      sed -i "s/#${element}.*/${element}=${num}/g" /etc/sysctl.conf
    fi
    if grep -q "^#\ ${element}" /etc/sysctl.conf; then
      sed -i "s/#\ ${element}.*/${element}=${num}/g" /etc/sysctl.conf
    fi
    if grep -q "^${element}" /etc/sysctl.conf; then
      sed -i "s/${element}.*/${element}=${num}/g" /etc/sysctl.conf
    fi
    if ! grep -q "${element}" /etc/sysctl.conf; then
      echo "${element}=${num}" >> /etc/sysctl.conf
    fi
  done
}

update_sysconfig 0 ${NET_CONFIG_ZED[@]}
update_sysconfig 1 ${NET_CONFIG_ONE[@]}

sysctl -w net.ipv6.route.flush=1

# 3.3.3 - Ensure IPv6 is disabled
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network
echo "options ipv6 disable=1" >> /etc/modprobe.d/ipv6.conf
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.d/ipv6.conf

# 3.4 - TCP Wrappers


# 5.2 SSH Server Configuration
# 5.2.1
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

declare -A SSH_CONFIG

SSH_CONFIG["Protocol"]="2"                                    # 5.2.2
SSH_CONFIG["LogLevel"]="INFO"                                 # 5.2.3
SSH_CONFIG["X11Forwarding"]="no"                              # 5.2.4
SSH_CONFIG["MaxAuthTries"]="4"                                # 5.2.5
SSH_CONFIG["IgnoreRhosts"]="yes"                              # 5.2.6
SSH_CONFIG["HostbasedAuthentication"]="no"                    # 5.2.7
SSH_CONFIG["PermitRootLogin"]="without-password"              # 5.2.8 (Should be no, but modified for now)
SSH_CONFIG["PermitEmptyPasswords"]="no"                       # 5.2.9
SSH_CONFIG["PermitUserEnvironment"]="no"                      # 5.2.10
SSH_CONFIG["Ciphers"]="aes128-ctr,aes192-ctr,aes256-ctr"      # 5.2.11
# 5.2.12
SSH_CONFIG["MACs"]="hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com"
SSH_CONFIG["ClientAliveInterval"]="300"                       # 5.2.13
SSH_CONFIG["ClientAliveCountMax"]="0"                         # 5.2.13
SSH_CONFIG["LoginGraceTime"]="60"                             # 5.2.14
SSH_CONFIG["Banner"]="\/etc\/issue.net"                       # 5.2.16

for key in ${!SSH_CONFIG[@]}; do
  if grep -q "^#${key}" /etc/ssh/sshd_config; then
    sed -i "s/#${key}.*/${key} ${SSH_CONFIG[${key}]}/g" /etc/ssh/sshd_config
  fi
  if grep -q "^#\ ${key}" /etc/ssh/sshd_config; then
    sed -i "s/#\ ${key}.*/${key} ${SSH_CONFIG[${key}]}/g" /etc/ssh/sshd_config
  fi
  if grep -q "^${key}" /etc/ssh/sshd_config; then
    sed -i "s/${key}.*/${key} ${SSH_CONFIG[${key}]}/g" /etc/ssh/sshd_config
  fi
  if ! grep -q "${key}" /etc/ssh/sshd_config; then
    echo "${key} ${SSH_CONFIG[${key}]}" >> /etc/ssh/sshd_config
  fi
done

systemctl restart sshd.service

# 6.1 System file permissions
6_1_SYSTEM_FILES=(
  "/etc/passwd"   root:root 644
  "/etc/shadow"   root:root 000
  "/etc/group"    root:root 644
  "/etc/gshadow"  root:root 600
  "/etc/passwd-"  root:root 600
  "/etc/shadow-"  root:root 600
  "/etc/group-"   root:root 600
  "/etc/gshadow-" root:root 600
  
)