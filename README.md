# Docker Swarm Mode Tests
Docker container to run tests on docker swarm mode cluster. These test stops docker service and reboots server, so it is not recommended for production use.
We are working on creating a mode, in which it will inspect desired state and will run verification on current setup, without performing any destructive operations. Current installation and un-installation scripts are specific for ubuntu 14.04. It is recommended for now to use ubuntu 14.04 as test servers. 

## WARNINGS
  1. **DO NOT RUN it on production**
  2. **It will remove all existing services, if any.**
  3. **It will remove overlay network with name "test-overlay-network", if <existing class=""></existing> 

## Instructions to set up 
  1. Setup SSH (skip this step, if ssh key authentication is already set up.)
    1. ssh-keygen on your local machine
    2. Copy your ssh public key on test servers by using ssh-copy-id
    ```
    ssh-keygen
    ssh-copy-id <server1>
    ssh-copy-id <server2>
    ssh-copy-id <server3>
    ```
  2. Edit environment-variables file
    1.  Update SERVERS variable, it is comma separated list of test servers. IP address or hostname will work. 
    2.  Update SSH_USER_NAME, provide user name which has sudo access to test servers.
    3.  Update SSH_PASSWORD, provide password for user. If sudo NOPASSWD is configured, then leave it blank.
    4.  UNINSTALL_DOCKER, if true will uninstall docker from all the servers as first step. Default is false.
    5.  INSTALL_DOCKER, if true will try to install docker and add servers to swarm. If docker is already install it will not do anything. Default is false. 
    6.  DOCKER_VERSION, docker version to install. INSTALL_DOCKER should be true.
    7.  SERVICE_SETUP, Sets up initial server. Initial service setup is recommended for now. 
    8.  RUN_SCALE_UP_DOWN_TEST, If true will randomly scale up/down the test services and will validate the cluster state.
    9.  RUN_DRAIN_TEST, If true will randomly drain one node , validate, get the node back and then validate and then perform same step on one another node.
    10. RUN_SERVER_UPGRADE_TEST, If true will drain node, stop docker, restart server and make node available again on each server. 
    11. RUN_UNPLANNED_SHUTDOWN_TEST, If true will restart a random server and bring it back again.
    12. Optionally, Secure environment-variables file
  3. Update docker-swarm-test.sh
    1. Update env-file path
    2. Update volume for SSH-keys. These are normally located under .ssh folder in user home directory
    3. Update volume for logs folder, this is where summary and detailed logs will be logged.
  4. Run docker-swarm-test.sh
    ```
    sudo ./docker-swarm-test.sh
    ``` 
  5. Once finished it will create a log folder which will have summary.log and details.log. In summary.log Test steps, errors and warnings are logged.
     In details.log it will log, all the commands and results it had run on any server. It will also have everything which is in summary.log
     Current tests also have curl test, it will keep on sending and logging curl test. If there are any non 200 responses, it will log as error.
