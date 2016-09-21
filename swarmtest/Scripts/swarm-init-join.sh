#!/bin/bash
install_mode=${1:-init}
host_ip_address=$(/sbin/ifconfig -a |grep eth0 -A 1|grep 'inet addr'|sed 's/\:/ /'|awk '{print $3}')

#check if we are already in an active swarm
swarm_state=$(docker info | grep 'Swarm:' | awk '{print $2}')

if [ $swarm_state == "active" ]; then
    echo "Already in a swarm"
elif [ $swarm_state == "inactive" ]; then
    if [ $install_mode == "init" ]; then

    echo "initiating swarm"
    docker swarm init \
        --advertise-addr $host_ip_address:2377 \
        --listen-addr $host_ip_address:2377 

    else
        join_token=${2:-}
        manager1_ip_address=${3:-}

        echo -n "Joining swarm as Manager"
        echo -n "Token:$join_token"
        echo -n "Leader IP:$manager1_ip_address"
        docker swarm join \
            --token $join_token \
            --advertise-addr $host_ip_address:2377 \
            --listen-addr $host_ip_address:2377 \
            $manager1_ip_address:2377

    fi
fi
