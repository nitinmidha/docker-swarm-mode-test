#!/bin/bash


function func_drain_test(){

    server_count=${#servers[@]}
    if [ "$server_count" -lt 2 ]; then
        func_log "Need at least 2 servers for drain test."
        return
    fi
    
    random_server_index_1=$(($RANDOM % $server_count))
    random_server_index_2=$(($RANDOM % $server_count))

    while [ $random_server_index_2 == $random_server_index_1 ]; do
        random_server_index_2=$(($RANDOM % $server_count))
    done

    server_to_drain_1="${servers[$random_server_index_1]}"
    server_to_drain_2="${servers[$random_server_index_2]}"


    func_log "Testing Swarm Drain. We will drain one node ($server_to_drain_1) and verify, then we will get that node back and drain another node ($server_to_drain_2)"
    current_test_name="Drain Test"
    func_init_test
    func_drain_node_and_active_in_end $server_to_drain_1
    func_log "Sleeping for 120s. Before draining $server_to_drain_2"
    sleep 120s
    func_drain_node_and_active_in_end $server_to_drain_2
    func_end_test
}

function func_drain_node_and_active_in_end(){
    server_to_drain=$1
    current_test_phase="$server_to_drain Drain"
    func_log "Draining server:$server_to_drain" 
    node_id=$(echo "$servers_node_id_map_string" | grep "$server_to_drain"| awk '{print $2}')
    command="$UPDATE_NODE_DRAIN $node_id"
    
    func_run_remote_simple_command "$server_to_drain" "$command"
    # sleep for 2 mins for changes to take effect.
    func_log "Sleeping for 120s for changes to take effect"
    sleep 120s
    unset desired_node_state
    unset active_servers
    for server in "${servers[@]}"; do
        node_id=$(echo "$servers_node_id_map_string" | grep "$server" | awk '{print $2}')
        if [ "$server_to_drain" == "$server" ]; then
            desired_node_state=("${desired_node_state[@]}" "$node_id Ready Drain 'Leader\|Reachable'")
        else
            desired_node_state=("${desired_node_state[@]}" "$node_id Ready Active 'Leader\|Reachable'")
        fi
        active_servers=("${active_servers[@]}" "$server")
    done
    func_verify

    func_log "Updating server:$server_to_drain to active"
    current_test_phase="Drain Test $server_to_drain Active" 
    node_id=$(echo "$servers_node_id_map_string" | grep "$server_to_drain"| awk '{print $2}')
    command="$UPDATE_NODE_ACTIVE $node_id"
    
    func_run_remote_simple_command "$server_to_drain" "$command"
    # sleep for 2 mins for changes to take effect.
    func_log "Sleeping for 120s for changes to take effect"
    sleep 120s
    func_set_default_desired_state
    func_verify
}

