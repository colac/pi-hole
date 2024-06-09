#!/bin/bash

### Prepare ubuntu 24.x to run docker pi-hole ###

#===============Initializations===============#

# Logs
timeStamp=$(date '+%Y%m%d_%H%M%S')
logFile=log_${timeStamp}.log

# Used to determine if old docker* versions should be removed (preferably yes)
rmv_old_docker=$1

# Used to create docker pi-hole
storageLocation="$HOME"
networkInterface="eth0"
timezone="Europe/Lisbon"

#===============Functions Declaration===============#

funcCheckSudo (){
    # Checks if $USER can run commands without typing sudo. If it cant, add them to docker group
    sudo -v
    if { sudo -v; } then
        printf "SUCCESS - User runs commands without prefacing them with sudo\n" | tee --append $logFile
    else
        printf "FAIL - %s cant run commands without prefacing them with sudo\n" $USER | tee --append $logFile
        sudo groupadd docker
        sudo usermod -aG docker $USER
    fi
}

funcRemoveOldDocker (){
    # Remove versions of docker, podman-docker, etc, to avoid conflicts
    # https://docs.docker.com/engine/install/ubuntu/
    if [[ $rmv_old_docker == 'yes' || $rmv_old_docker == 'y' ]]; then
        printf "Removing old docker* versions\n" | tee --append $logFile
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
        do
            printf '%s \n' $pkg | tee --append $logFile
            #sudo apt-get remove $pkg
        done
    elif [[ $rmv_old_docker == 'no' || $rmv_old_docker == 'n' ]]; then
        printf "Keeping old docker* versions\n" | tee --append $logFile
    else
        exit 1
    fi
}

funcInstallDocker (){
    # https://docs.docker.com/engine/install/ubuntu/#installation-methods
    printf "Preparing for Docker install\n" | tee --append $logFile
    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    printf "Installing Docker\n" | tee --append $logFile
    # Install docker
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Check if docker is installed
    sudo docker run hello-world
}

#===============Script Execution===============#

if [ $# -lt 1 ]; then
    printf "To remove old versions of docker* type "yes" after invoking the script, or "no" to keep them. All other values are provided by default. \nhttps://docs.docker.com/engine/install/ubuntu/#uninstall-old-versions\n" | tee --append $logFile
fi

funcRemoveOldDocker $rmv_old_docker
funcInstallDocker
funcCheckSudo
