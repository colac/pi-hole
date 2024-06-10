#!/bin/bash

### Creates the backup file in pihole and copies it to NAS. This is executed on the NAS ###

#===============Initializations===============#

# Define variables
remoteUser=<USER>
remoteHost=<IP>
sshKeyPath=<SSHKEY>
fileName="pihole_backup_$(date '+%Y-%m-%d').tar.gz"
dockerCommandBackup="docker exec -it pihole /bin/bash -c 'cd /etc/pihole && pihole -a -t'"
CommandRename="cp /home/$remoteUser/etc-pihole/pi-hole-pi_hole-teleporter_$(date '+%Y-%m-%d_')* /home/$remoteUser/$fileName"

#===============Script Execution===============#

# Connect to the remote server via SSH and execute the Docker command
ssh -i "$sshKeyPath" "$remoteUser@$remoteHost" "$dockerCommandBackup"
ssh -i "$sshKeyPath" "$remoteUser@$remoteHost" "$CommandRename"
scp -i "$sshKeyPath" "$remoteUser@$remoteHost:/home/$remoteUser/$fileName" "$fileName"

if [ ! -f "$fileName" ]; then
    echo -e "File not found locally $filename"
    exit 1
fi
