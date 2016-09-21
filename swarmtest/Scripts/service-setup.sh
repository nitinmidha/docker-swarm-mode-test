#!/bin/bash
overlay_network="test-overlay-network"
reverse_proxy_service_name="test-nginx"
reverse_proxy_published_port=80
reverse_proxy_image="nitinmidha/test-nginx"
test_api_1_service_name="test-api1"
test_api_2_service_name="test-api2"
test_api_image="nitinmidha/node-test-api"


docker service ls | grep -v IMAGE | awk '{print $1}' | xargs --no-run-if-empty docker service rm
sleep 10s
docker network ls | grep -w $overlay_network | awk '{print $1}' | xargs --no-run-if-empty docker network rm
sleep 10s
network_exists=$(docker network ls | grep -w $overlay_network)
if [ -z "$network_exists" ]; then
  echo "Network: $overlay_network does not exists"
  docker network create -d overlay $overlay_network
fi

service_exists=$(docker service ls | grep -w $test_api_1_service_name)

if [ -z "$service_exists" ]; then
  echo "Service: $test_api_1_service_name does not exists"
  command="docker service create \
            --name $test_api_1_service_name \
            --network $overlay_network \
            --replicas 2 \
            "
  command="$command "" $test_api_image"
  echo $command
  $command
fi

service_exists=$(docker service ls | grep -w $test_api_2_service_name)

if [ -z "$service_exists" ]; then
  echo "Service: $test_api_2_service_name does not exists"
  command="docker service create \
            --name $test_api_2_service_name \
            --network $overlay_network \
            --replicas 2 \
            "
  command="$command "" $test_api_image"
  echo $command
  $command
fi


sleep 120s

service_exists=$(docker service ls | grep -w $reverse_proxy_service_name)

if [ -z "$service_exists" ]; then
  echo "Service: $reverse_proxy_service_name does not exists"
  command="docker service create \
            --name $reverse_proxy_service_name \
            --network $overlay_network \
            --mode global \
            --publish $reverse_proxy_published_port:80 \
            "
  command="$command "" $reverse_proxy_image"
  echo $command
  $command
fi
