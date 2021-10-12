#!/bin/bash

# Make sure only root can run our script
if [ "$EUID" -ne 0 ]; then
   echo "You're not root, are you?" 1>&2
   echo "Please use sudo" 1>&2
   exit 1
fi

timestamp=`/bin/date +"%FT%H%M%S"`
reboot_hour=`/usr/bin/shuf -i 0-23 -n1`
reboot_min=`/usr/bin/shuf -i 10-59 -n1`
reboot_time=$reboot_hour:$reboot_min

if [ -f /usr/bin/unattended-upgrades ]; then
	echo "Backing up default configs"
	/bin/cp -v /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.bak-$timestamp
	/bin/cp -v /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.bak-$timestamp
else 
	echo "unattended-upgrades might not be installed.. attempting to install"
	/bin/apt update && /bin/apt install --yes unattended-upgrades
fi

echo "Creating new /etc/apt/apt.conf.d/50unattended-upgrades..."
/bin/cat <<"EOF">/etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
        "${distro_id}ESMApps:${distro_codename}-apps-security";
        "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
// Enable logging to syslog. Default is False
Unattended-Upgrade::SyslogEnable "true";
// Specify syslog facility. Default is daemon
Unattended-Upgrade::SyslogFacility "daemon";
Unattended-Upgrade::Automatic-Reboot "true";
EOF
echo 'Unattended-Upgrade::Automatic-Reboot-Time "'$reboot_time'";' >> /etc/apt/apt.conf.d/50unattended-upgrades

/bin/cat /etc/apt/apt.conf.d/50unattended-upgrades

echo "This server has been scheduled to rebbot at $reboot_time after patches are installed if required"

echo " "
echo "Creating new /etc/apt/apt.conf.d/20auto-upgrades"
/bin/cat <<EOF>/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

/bin/cat /etc/apt/apt.conf.d/20auto-upgrades

echo " "
echo "All done"
