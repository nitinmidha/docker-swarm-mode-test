#!/bin/bash


function func_unplanned_failure_test(){
    func_log "Testing unplanned server failure. We will pick one random server and reboot it without draining."
    current_test_name="Server Failure Test"
    func_init_test
    server_count=${#servers[@]}
    random_server_index_1=$(($RANDOM % $server_count))
    test_server="${servers[$random_server_index_1]}"

    func_log_dtl "Stopping curl for server:$test_server"
    func_kill_curl_for_server "$test_server"
    
    func_log "Rebooting server:$test_server"
    func_run_remote_simple_command "$test_server" "$REBOOT"
    # We can not test an in-consistent state.
    # sleep 5s
    # unset desired_node_state
    # unset active_servers
    # for server in "${servers[@]}"; do
    #     node_id=$(echo "$servers_node_id_map_string" | grep "$server" | awk '{print $2}')
    #     if [ "$test_server" == "$server" ]; then
    #         desired_node_state=("${desired_node_state[@]}" "$node_id 'Ready\|Down\|Unkown' Active 'Unreachable'")
    #     else
    #         desired_node_state=("${desired_node_state[@]}" "$node_id Ready Active 'Leader\|Reachable'")
    #         active_servers=("${active_servers[@]}" "$server")
    #     fi
    # done
    # current_test_phase="$test_server down"
    # func_verify
    func_log "Sleeping for 240s. Hopefully server is back up by now."
    sleep 240s
    func_log_dtl "Initiating curl for server:$test_server"
    func_add_curl_for_server "$test_server"
    current_test_phase="$test_server up"
    func_verify
    func_end_test
}
