#!/bin/bash

### Create ssh key pair and outputs it. To configure pi-hole backup ###

#===============Initializations===============#

# Logs
timeStamp=$(date '+%Y%m%d_%H%M%S')
logFile=log_${timeStamp}.log

sshDirString='$HOME/.ssh'
sshKeyString='$HOME/.ssh/id_ed25519_nas'
sshDir="$HOME/.ssh"
sshKey="${sshDir}/id_ed25519_nas"

#===============Functions Declaration===============#

funcAuthKeysFile (){
    filePath="/etc/ssh/sshd_config"
    authLine="AuthorizedKeysFile     .ssh/authorized_keys"
    pubAuthLine="PubkeyAuthentication yes"
    sudo cp "$filePath" "$filePath"_"$timeStamp"
    # This condition "will do", but if the line is already uncommented it will add another one on the "else"
    printf "Replace "$filePath" in "$filePath"\n" | tee --append $logFile
    if grep -q '^#AuthorizedKeysFile*' "$filePath"; then
        printf "Found line, replacing\n" | tee --append $logFile
        sudo sed -i "s|^#AuthorizedKeysFile.*|$authLine|" "$filePath"
    else
        # If the line does not exist, ensure it is added correctly
        printf "Adding line\n" | tee --append $logFile
        sudo bash -c "echo -e '$authLine' >> '$filePath'"
    fi

    printf "Replace "$pubAuthLine" in "$filePath"\n" | tee --append $logFile
    if grep -q '^#PubkeyAuthentication*' "$filePath"; then
        printf "Found "$pubAuthLine", replacing\n" | tee --append $logFile
        sudo sed -i "s|^#PubkeyAuthentication.*|$pubAuthLine|" "$filePath"
    else
        # If the line does not exist, ensure it is added correctly
        printf "Adding "$pubAuthLine"\n" | tee --append $logFile
        sudo bash -c "echo -e '$pubAuthLine' >> '$filePath'"
    fi

    echo -e "Pray and hope I didn't make a mistake!\nRestarting sshd service"
    sudo systemctl restart ssh.service

}

#===============Script Execution===============#

# Create ssh key pair on pihole
sudo -v
rm "$sshKey"
ssh-keygen -t ed25519 -N "" -f "$sshKey"
pubKey=$(cat "$sshKey.pub")
echo -e "$pubKey" >> "$sshDir/authorized_keys"
chmod 644 "$sshDir/authorized_keys"

# Commands for NAS
privKeyBase64=$(base64 -w 0 "$sshKey")
pubKeyBase64=$(base64 -w 0 "$sshKey.pub")

networkInterface="eth0"
ipAddress=$(ip -br addr show | awk -v iface="$networkInterface" '$1 == iface {print $3}' | cut -d'/' -f1)

echo -e "\nConnect via ssh to the NAS and execute the following command:\n"
# Prepare the command with variable substitution
commandSetup="mkdir -p \"$sshDirString\" && chmod 700 \"$sshDirString\" && echo -n \"$privKeyBase64\" | base64 --decode > \"$sshKeyString\" && echo -n \"$pubKeyBase64\" | base64 --decode > \"$sshKeyString.pub\" && chmod 600 $sshDirString/*"

commandConnect="ssh -i \"$sshKeyString\" -v "$USER"@"$ipAddress""
# Output the command for the user to copy and run
printf '%s\n\n' "$commandSetup"
printf '%s\n\n' "$commandConnect"

funcAuthKeysFile
