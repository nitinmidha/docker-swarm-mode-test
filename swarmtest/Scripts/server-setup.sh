#!/bin/bash


function func_uninstall_docker(){
    # do clean up on each servers
    for server in "${servers[@]}"; do
        func_log "Uninstalling docker on:$server"
        command=$(cat docker-uninstall.sh)
        func_run_remote_command "$server" "$command"
        func_run_remote_simple_command "$server" "$REBOOT"
        func_log "Sleeping for 120 seconds, so that server can reboot"
        sleep 120s
        func_run_remote_simple_command "$server" "$DOCKER_LIB_FOLDER_CLEANUP"
        func_run_remote_simple_command "$server" "$DOCKER_RUN_FOLDER_CLEANUP"
    done
}

function func_install_docker(){
    # install docker on each server
    for server in "${servers[@]}"; do
        func_log "Installing Docker on: $server"
        command=$(cat docker-setup.1.12.x.sh)
        func_run_remote_command "$server" "$command" "$docker_version_to_install"
    done
    is_swarm_initialized="false"
    swarm_manager_join_token=""
    leader_server_ip=""
    # install docker on each server
    for server in "${servers[@]}"; do
        
        if [ $is_swarm_initialized == "false" ]; then
            command=$(cat swarm-init-join.sh)
            func_run_remote_command "$server" "$command"
            swarm_manager_join_token=$(func_run_remote_simple_command "$server" "$GET_SWARM_MANAGER_JOIN_TOKEN")

            leader_server_ip=$(func_run_remote_simple_command "$server" "$GET_IP_ADDRESS")
            is_swarm_initialized="true"
            func_log "Initialized swarm on $server with ip address:$leader_server_ip"
        else
            func_log "Joining Swarm on $server Leader server ip is:$leader_server_ip; Manager Join Token is:$swarm_manager_join_token"
            command=$(cat swarm-init-join.sh)
            func_run_remote_command "$server" "$command" "join" "$swarm_manager_join_token" "$leader_server_ip"
        fi
    done
}

function func_setup_ipvsadm_nsenter(){
    # install docker on each server
    for server in "${servers[@]}"; do
        func_log "Setting up ipvsadm and nsenter on: $server"
        command=$(cat setup-ipvsadm-nsenter.sh)
        func_run_remote_command "$server" "$command"
    done
}
