#!/bin/bash
# docker service ls | grep -v NAME | awk '{print $2}' | xargs --no-run-if-empty docker service rm
# sleep 30s
# docker ps -a | grep -v CONTAINER | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
# sleep 10s
# docker images | grep -v IMAGE | awk '{print $3}' | xargs --no-run-if-empty docker rmi
# sleep 10s
# docker network ls | grep -v NAME | grep 'appserver\|dbserver' | awk '{print $2}' | xargs --no-run-if-empty docker network rm
# sleep 10s

# docker volume ls | grep -v NAME | awk '{print $2}' | xargs --no-run-if-empty docker volume rm
# sleep 10s

function check_package_installed(){
    if dpkg --get-selections | grep -q "^$1[[:space:]]*" >/dev/null; then
        return 0
    else
        return 1
    fi
}
package_to_check=docker-engine
if check_package_installed $package_to_check; then
    echo "$package_to_check is installed. Cleaning ..."
    service docker stop
    sleep 30s
    apt-get -y purge docker-engine
    sleep 10s
    apt-get -y autoremove --purge docker-engine
    sleep 10s
    rm -rfv /var/lib/docker
    sleep 10s
    rm -rfv /var/run/docker
 else    
     echo "$package_to_check is not installed."
 fi


 