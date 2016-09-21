#!/bin/bash
container_name="swarm-test-1"
remote_image=nitinmidha/docker-swarm-mode-test
docker rm -f "$container_name"
docker run -d \
    --name swarm-test-1 \
    --net=host \
    --env-file ./environment-variables \
    -v ~/.ssh/azure_rsa:/root/.ssh/id_rsa:ro \
    -v ~/src/github/docker-swarm-mode-test/logs:/var/log/swarm-test \
    "$remote_image"

docker logs -f "$container_name"