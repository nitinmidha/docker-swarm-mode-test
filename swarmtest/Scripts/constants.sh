#!/bin/bash

#constants
readonly SERVICE_MODE_REPLICATED="Replicated"
readonly SERVICE_MODE_GLOBAL="Global"
readonly SUCCESS_PREFIX="SUCCESS"
readonly FAILURE_PREFIX="FAIL"
readonly WARN_PREFIX="WARN"
#
#commands
readonly GET_IP_ADDRESS="/sbin/ifconfig -a |grep eth0 -A 1|grep 'inet addr'|sed 's/\:/ /'|awk"' '"'"'{print $3}'"'"''
readonly GET_SWARM_MANAGER_JOIN_TOKEN="docker swarm join-token -q manager"
readonly REBOOT="shutdown -r now"
readonly DOCKER_LIB_FOLDER_CLEANUP="rm -rfv /var/lib/docker"
readonly DOCKER_RUN_FOLDER_CLEANUP="rm -rfv /var/run/docker"
readonly LIST_SWARM_NODE="docker node ls"
readonly INSPECT_SERVICE="docker service inspect "
readonly INSPECT_CONTAINER="docker inspect"
readonly GET_IP_ADRESS_CONTAINER_ON_NET_TEST_OVERLAY="docker inspect --format '{{ ( ( index .NetworkSettings.Networks \"test-overlay-network\" ) 0).IPAMConfig.IPv4Address }}'"
readonly GET_IP_ADRESS_CONTAINER_ON_NET_INGRESS="docker inspect --format '{{ ( ( index .NetworkSettings.Networks \"ingress\" ) 0).IPAMConfig.IPv4Address }}'"
readonly GET_PUBLISHED_PORT=" docker service inspect --format '{{(index (index .Endpoint.Ports) 0).PublishedPort }}'"
readonly GET_SERVICE_VIP="docker service inspect --format '{{(index (index .Endpoint.VirtualIPs) 0).Addr }}' "
readonly GET_SERVICE_VIP_1="docker service inspect --format '{{(index (index .Endpoint.VirtualIPs) 1).Addr }}' "
readonly LIST_SWARM_SERVICES="docker service ls"
readonly LIST_SERVICE_TASK="docker service ps "
readonly LIST_RUNNING_CONTAINERS="docker ps "
readonly GET_CONTAINER_SANDBOX_KEY="docker inspect --format '{{.NetworkSettings.SandboxKey}}'"
readonly GET_NAMESPACES="ls /var/run/docker/netns"
readonly UPDATE_NODE_DRAIN="docker node update --availability drain "
readonly UPDATE_NODE_ACTIVE="docker node update --availability active "
readonly GET_CURRENT_NODE_ID="docker node ls | grep '*' | awk"' '"'"'{print $1, $3}'"'"''
readonly SERVICE_SCALE="docker service scale "
readonly SERVICE_DOCKER_STOP="service docker stop"