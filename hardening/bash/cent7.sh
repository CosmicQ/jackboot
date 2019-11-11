#!/bin/bash

# Simple bash script to get hardening started (CIS Level 1)

# 1.1.1.1-8 - Disable Filesystems
FILESYSTEMS=(cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat)
touch /etc/modprobe.d/CIS.conf
for FS in "${FILESYSTEMS[@]}"
do
  if ! grep $FS /etc/modprobe.d/CIS.conf; then
    echo "Disabling $FS in /etc/modprobe.d/CIS.conf.."
    echo "install $FS /bin/true" >> /etc/modprobe.d/CIS.conf
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
