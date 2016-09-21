#!/bin/bash


function func_upgrade_test(){
    func_log "Testing upgrade. Each Server will be drained. Services would be stopped and then server would be restarted and added back to pool"
    current_test_name="Server Upgrade Test"
    func_init_test
    for server in "${servers[@]}"; do
        func_server_upgrade $server
    done
    func_end_test
}


function func_server_upgrade(){
    server_for_upgrade=$1
    current_test_phase="$server_for_upgrade Drain"
    func_log "Draining server:$server_for_upgrade" 
    node_id=$(echo "$servers_node_id_map_string" | grep "$server_for_upgrade"| awk '{print $2}')
    command="$UPDATE_NODE_DRAIN $node_id"
    
    func_run_remote_simple_command "$server" "$command"
    # sleep for 2 mins for changes to take effect.
    func_log "Sleeping for 120s for changes to take effect"
    sleep 120s
    unset desired_node_state
    unset active_servers
    for server in "${servers[@]}"; do
        node_id=$(echo "$servers_node_id_map_string" | grep "$server" | awk '{print $2}')
        if [ "$server_for_upgrade" == "$server" ]; then
            desired_node_state=("${desired_node_state[@]}" "$node_id Ready Drain 'Leader\|Reachable'")
        else
            desired_node_state=("${desired_node_state[@]}" "$node_id Ready Active 'Leader\|Reachable'")
        fi
        active_servers=("${active_servers[@]}" "$server")
    done
    func_verify

    current_test_phase="$server_for_upgrade Down"

    func_log_dtl "Stopping curl for server:$server_for_upgrade"
    func_kill_curl_for_server "$server_for_upgrade"

    func_log "Stopping server:$server_for_upgrade" 
    
    func_run_remote_simple_command "$server_for_upgrade" "$SERVICE_DOCKER_STOP"
    # sleep for 2 mins for changes to take effect.
    func_log "Sleeping for 120s for changes to take effect."
    sleep 120s

    unset desired_node_state
    unset active_servers
    for server in "${servers[@]}"; do
        node_id=$(echo "$servers_node_id_map_string" | grep "$server" | awk '{print $2}')
        if [ "$server_for_upgrade" == "$server" ]; then
            desired_node_state=("${desired_node_state[@]}" "$node_id Down Drain 'Unreachable'")
        else
            desired_node_state=("${desired_node_state[@]}" "$node_id Ready Active 'Leader\|Reachable'")
            active_servers=("${active_servers[@]}" "$server")
        fi
    done
    func_verify

    func_log "Rebooting server:$server_for_upgrade"
    func_run_remote_simple_command "$server_for_upgrade" "$REBOOT"

    func_log "Sleeping for 240s for changes to take effect."
    sleep 240s

    func_log_dtl "Initiating curl for server:$server_for_upgrade"
    func_add_curl_for_server "$server_for_upgrade"


    func_log "Updating server:$server_for_upgrade to active"
    current_test_phase="$server_for_upgrade Active" 
    node_id=$(echo "$servers_node_id_map_string" | grep "$server_for_upgrade"| awk '{print $2}')
    command="$UPDATE_NODE_ACTIVE $node_id"
    
    func_run_remote_simple_command "$server_for_upgrade" "$command"
    # sleep for 2 mins for changes to take effect.
    func_log "Sleeping for 120s for changes to take effect"
    sleep 120s
    func_set_default_desired_state
    func_verify
}