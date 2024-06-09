#!/bin/bash

### Run docker pi-hole ###

#===============Initializations===============#

# Logs
timeStamp=$(date '+%Y%m%d_%H%M%S')
logFile=log_${timeStamp}.log

# Used to create docker pi-hole
storageLocation="$HOME"
networkInterface="eth0"
timezone="Europe/Lisbon"

#===============Functions Declaration===============#

funcDisableSystendResolved (){
    # http://web.archive.org/web/20220612212822/https://www.bklynit.net/ubuntu-20-04-lts-docker-pihole/
    # https://askubuntu.com/questions/1394034/port-conflict-in-pi-hole-docker-installation-with-systemd-resolve-process

    printf "Replace line in /etc/systemd/resolved.conf" | tee --append $logFile
    # Replace #DNSStubListener=yes with DNSStubListener=no
    if grep -q '^#DNSStubListener=yes' /etc/systemd/resolved.conf; then
        sudo sed -i 's/^#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    else
        # If the line does not exist, ensure it is removed and added correctly
        sudo sed -i '/^#DNSStubListener=yes/d' /etc/systemd/resolved.conf
        sudo sed -i '/^\[Resolve\]/a DNSStubListener=no' /etc/systemd/resolved.conf
    fi

    sudo systemctl restart systemd-resolved.service
    # Fix local DNS name resolution
    sudo rm /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

}

funcCreatePiHole (){
    # https://github.com/pi-hole/docker-pi-hole/blob/master/README.md

    PIHOLE_BASE="$storageLocation"
    [[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { printf "Couldn't create storage directory: %s" $PIHOLE_BASE | tee --append $logFile; exit 1; }

    # Network interface/IP 
    ipAddress=$(ip -br addr show | awk -v iface="$networkInterface" '$1 == iface {print $3}' | cut -d'/' -f1)
    printf "The IP address of %s is: %s\n" $networkInterface $ipAddress | tee --append $logFile

    printf 'Starting up pihole container\n' | tee --append $logFile
    # Note: FTLCONF_LOCAL_IPV4 should be replaced with your external ip.
    # remove old container of pihole
    docker rm pihole
    # Create pihole container
    docker run -d \
        --name pihole \
        -p 53:53/tcp -p 53:53/udp \
        -p 80:80 \
        -e TZ="$timezone" \
        -v "${PIHOLE_BASE}/etc-pihole:/etc/pihole" \
        -v "${PIHOLE_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d" \
        --dns=$ipAddress --dns=1.1.1.1 \
        --restart=unless-stopped \
        --hostname pi.hole \
        -e VIRTUAL_HOST="pi.hole" \
        -e PROXY_LOCATION="pi.hole" \
        -e FTLCONF_LOCAL_IPV4="$ipAddress" \
        pihole/pihole:latest

    printf 'Checking pihole container\n' | tee --append $logFile
    for i in $(seq 1 20); do
        if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
            printf 'OK\n' | tee --append $logFile
            printf "\n$(docker logs pihole 2> /dev/null | grep 'password:') for your pi-hole: http://${ipAddress}/admin/\n" | tee --append $logFile
            exit 0
        else
            sleep 3
            printf '.\n' | tee --append $logFile
        fi

        if [ $i -eq 20 ] ; then
            printf "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)\n" | tee --append $logFile
            exit 1
        fi
    done;
}

#===============Script Execution===============#

if funcDisableSystendResolved; then
    funcCreatePiHole
fi