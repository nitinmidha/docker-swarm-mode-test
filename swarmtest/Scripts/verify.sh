#!/bin/bash

function func_verify_response(){
    command=$2
    for r in $3; do
        command="$command | grep $r"
    done
    command="$command | wc -l"
    command='echo "$1" | '$command
    matched=$(eval $command )
    if [ "$matched" == "1" ]; then
        func_log_result "$SUCCESS_PREFIX" "State:$3 is matched"
        return 1
    else
        func_log_result "$FAILURE_PREFIX" "$3 is not matched"
        return 0
    fi
}

function func_verify_nodes(){
    func_log_dtl "Verifying Nodes"
    desired_state=("${@}")
    current_test_step="VerifySwarmNodes"
    server="${active_servers[0]}"
    swarm_nodes_response=$(func_run_remote_simple_command "$server" "$LIST_SWARM_NODE")
    current_active_node_count=$(echo "$swarm_nodes_response" | grep 'Ready' | grep 'Active' | grep -c 'Leader\|Reachable')
    func_log_dtl "Node List:$swarm_nodes_response"
    func_log_dtl "Current Active node count is:$current_active_node_count"
    is_success=0
    for state in "${desired_state[@]}"; do
        #echo "Testing:$state"
        command="sed 's/\*//g' | grep -v HOSTNAME "
        func_verify_response "$swarm_nodes_response" "$command" "$state"
    done
}

function func_verify_service(){
    service_name=$1
    server=${active_servers[0]}
    command="$INSPECT_SERVICE $service_name"
    service_inspect_response=$(func_run_remote_simple_command "$server" "$command")
    func_log_dtl "$service_inspect_response"  
    service_mode_grep=$(echo "$service_inspect_response" | grep $SERVICE_MODE_REPLICATED)
    container_instance_desired=0
    if [ -z "$service_mode_grep" ]; then
        service_mode=$SERVICE_MODE_GLOBAL
        #container_instance_desired=${#active_servers[@]}
        container_instance_desired=$current_active_node_count
    else
        service_mode=$SERVICE_MODE_REPLICATED
        container_instance_desired=$(echo "$service_inspect_response" | grep "Replicas" | awk '{print $2}')
    fi
    func_log_dtl "Verifying Service:$service_name Service mode:$service_mode Container Instances Desired:$container_instance_desired"
    command="$LIST_SERVICE_TASK $service_name"
    service_tasks_response=$(func_run_remote_simple_command "$server" "$command")
    func_log_dtl "$service_tasks_response"
    service_tasks_response_cleaned=$(echo "$service_tasks_response" |  sed 's/\\_//g' | awk '{print $1,$2,$4,$6}')
    func_log_dtl "$service_tasks_response_cleaned"
    service_task_running=$(echo "$service_tasks_response_cleaned" |  grep Running)
    func_log_dtl "$service_task_running"
    readarray -t service_task_running_array <<< "$service_task_running"
    
    service_task_running_count=$(echo  "$service_task_running" | grep -c Running)
    
    if [ $service_task_running_count == $container_instance_desired ]; then
        func_log_result "$SUCCESS_PREFIX" "Service $service_name has $service_task_running_count task running"
    else
        func_log_result "$FAILURE_PREFIX" "Service $service_name has $service_task_running_count task running. Desired Count is:$container_instance_desired"
    fi

    func_log_dtl "Getting VIP"
    command="$GET_SERVICE_VIP $service_name"
    service_vip=$(func_run_remote_simple_command "$server" "$command" | awk -F '/' '{print $1}')
    func_log_dtl "Service $service_name has VIP:$service_vip"

    published_port_count=$(echo "$service_inspect_response" | grep -c PublishedPort)
    is_published="false"
    if [ $published_port_count -gt 0 ]; then
        is_published="true"
        func_log_dtl "Getting PublishedPort"
        command="$GET_PUBLISHED_PORT $service_name"
        published_port=$(func_run_remote_simple_command "$server" "$command")
        func_log_dtl "Service $service_name is published on $published_port"

        func_log_dtl "Getting VIP with index 1"
        command="$GET_SERVICE_VIP_1 $service_name"
        service_vip_1=$(func_run_remote_simple_command "$server" "$command" | awk -F '/' '{print $1}')
        func_log_dtl "Service $service_name has VIP:$service_vip_1"
    else
        published_port=""
        service_vip_1=""
    fi

    service_state=("${service_state[@]}" "$service_name $service_mode $service_task_running_count $service_vip $service_vip_1 $published_port")
    readarray -t service_task_running_array <<< "$service_task_running"
    for task in "${service_task_running_array[@]}"; do
        if [ -z "$task" ]; then
            func_log_dtl "Task is empty"
        else
            func_log_dtl "Task is:$task"
            server_local_name=$(echo "$task" | awk '{print $3}')
            server=$(echo "$servers_node_id_map_string" | grep "$server_local_name" | awk '{print $1}')
            task_id=$(echo "$task" | awk '{print $1}')
            running_containers=$(func_run_remote_simple_command "$server" "$LIST_RUNNING_CONTAINERS")
            func_log_dtl "Running containers on server:$server are: $running_containers"
            verify_task_id_count=$(echo "$running_containers" | grep -c $task_id)
            if [ $verify_task_id_count == 1 ]; then
                container_id=$(echo "$running_containers" | grep $task_id | awk '{print $1}')
                
                func_log_dtl "Getting IP Address of container for test-overlay-network"
                command="$GET_IP_ADRESS_CONTAINER_ON_NET_TEST_OVERLAY $container_id"
                container_ip_address=$(func_run_remote_simple_command "$server" "$command")
                command="$GET_CONTAINER_SANDBOX_KEY $container_id"
                sandbox_key=$(func_run_remote_simple_command "$server" "$command")
                func_log_dtl "Sandbox Key for container:$container_id is $sandbox_key"

                if [ $service_mode == $SERVICE_MODE_GLOBAL ]; then
                    func_log_dtl "Getting IP Address of container for ingress"
                    command="$GET_IP_ADRESS_CONTAINER_ON_NET_INGRESS $container_id"
                    container_ip_address_ingress=$(func_run_remote_simple_command "$server" "$command")
                    func_log_result "$SUCCESS_PREFIX" "Task $task_id is running on server:$server with container id:$container_id with IP Address:$container_ip_address, $container_ip_address_ingress"
                    service_containers=("${service_containers[@]}" "$service_name $container_id $sandbox_key $container_ip_address $container_ip_address_ingress")
                else
                    func_log_result "$SUCCESS_PREFIX" "Task $task_id is running on server:$server with container id:$container_id with IP Address:$container_ip_address"
                    service_containers=("${service_containers[@]}" "$service_name $container_id $sandbox_key $container_ip_address")
                fi
                
                
                                
            else
                func_log_result "$FAILURE_PREFIX" "Task $task_id is NOT running on server:$server"
            fi
            
        fi
    done

}

function func_verify_iptables(){
    for server in "${active_servers[@]}"; do
        func_log_dtl "Verifying IPTABLES On Server:$server"
        namespaces=$(func_run_remote_simple_command "$server" "$GET_NAMESPACES")
        readarray -t namespaces_array <<< "$namespaces"
        for ns in "${namespaces_array[@]}"; do
            command="./nsenter --net=/var/run/docker/netns/$ns iptables -nvL -t mangle"
            iptables_response=$(func_run_remote_simple_command "$server" "$command")
            command="./nsenter --net=/var/run/docker/netns/$ns ipvsadm"
            ipvsadm_response=$(func_run_remote_simple_command "$server" "$command")
            func_log_dtl "Mangle table for ns:$ns - $iptables_response"
            func_log_dtl "ipvsadm response for ns: $ns - $ipvsadm_response"
            readarray -t ipvsadm_response_array <<< "$ipvsadm_response"
            for state in "${service_state[@]}"; do
                service_name=$(echo "$state" | awk '{print $1}')
                service_mode=$(echo "$state" | awk '{print $2}')
                service_container_count=$(echo "$state" | awk '{print $3}')
                service_vip=$(echo "$state" | awk '{print $4}')
                service_vip_1=$(echo "$state" | awk '{print $5}')
                service_published_port=$(echo "$state" | awk '{print $6}')
                if [ -z "$service_vip_1" ]; then
                    func_log_dtl "service_vip_1 is empty"
                    vip_to_check=("vip $service_vip")
                else
                    func_log_dtl "service_vip_1 is:$service_vip_1"
                    vip_to_check=("vip $service_vip" "vip $service_vip_1" "port $service_published_port")
                fi
                func_log_dtl "Service:$service_name $service_mode $service_container_count $service_vip $service_vip_1 $service_published_port"

                # find MARK Sets

                for service_vip_check in "${vip_to_check[@]}"; do
                    func_log_dtl "Service to Check:$service_vip_check"
                    is_port=$(echo "$service_vip_check" | grep -c port)
                    #func_log $(echo "$iptables_response" |grep $vip | awk '{print $11,$12,$13}')
                    
                    if [ "$is_port" == 1 ]; then
                        match_string="dpt:$(echo "$service_vip_check" | awk '{print $2}')"
                        
                    else
                        match_string=$(echo "$service_vip_check" | awk '{print $2}')
                        
                    fi

                    func_log_dtl "Match String is:$match_string"
                    mark_count=$(echo "$iptables_response" |grep -c $match_string)
                    func_log_dtl "Mark Count is:$mark_count"

                    if [ "$mark_count" == 0 ]; then
                        func_log_dtl "No Service Entry found"
                    else
                        if [ "$mark_count" -gt 1 ]; then
                            func_log_result "$WARN_PREFIX" "On Server:$server; for NameSpace:$ns; $match_string has multiple mark set."
                        fi

                        if [ "$is_port" == 1 ]; then
                            func_log_dtl "Getting Mark Set for Port"
                            mark_base16=$(echo "$iptables_response" |grep "$match_string" | awk '{print $14}' | cut -c 3- | tail -n 1)
                        else
                            func_log_dtl "Getting Mark Set for IP Address"
                            mark_base16=$(echo "$iptables_response" |grep "$match_string" | awk '{print $12}' | cut -c 3- | tail -n 1)
                        fi
                        func_log_dtl "Mark base 16 is $mark_base16"
                        mark_base10=$((16#$mark_base16))
                        func_log_dtl "Mark base 10 is $mark_base10"
                        rows_to_scan=$(($service_container_count+1))
                        #echo $rows_to_scan
                        line_matched=$(echo "$ipvsadm_response" | grep -n "FWM  $mark_base10 rr" | cut -f1 -d:)
                        #echo $line_matched
                        func_log_dtl "Line Matched in IPVSADM:$line_matched"
                        ipvsadm_response_array_count="${#ipvsadm_response_array[@]}"
                        if [ -z "$line_matched" ]; then
                            func_log_result "$FAILURE_PREFIX" "On Server:$server; for NameSpace:$ns; for service:$service_name; for $match_string; Mark Set $mark_base16 with decimal value $mark_base10 was not found in IPVSADM"
                        else
                            containers_matched=0
                            containers_not_matched=0
                            # start looking at end of the file.
                            start_line=$(($line_matched+1))
                            for i in $(seq $start_line $ipvsadm_response_array_count); do
                                #array is 0 based index.
                                index=$(($i-1))

                                fwm_count=$(echo "${ipvsadm_response_array[index]}" | grep -c "FWM")

                                if [ $fwm_count == "1" ]; then
                                    if [ "$containers_matched" = "$service_container_count" ]; then
                                        # All good ...
                                        func_log_result "$SUCCESS_PREFIX" "On Server:$server; for NameSpace:$ns; for service:$service_name; for $match_string; Next Mark Set Started. This mark set only has $containers_matched matching ips and $containers_not_matched un-matched ips. Desired # of ips are $service_container_count"
                                    else
                                        func_log_result "$FAILURE_PREFIX" "On Server:$server; for NameSpace:$ns; for service:$service_name; for $match_string; Next Mark Set Started. This mark set only has $containers_matched matching ips and $containers_not_matched un-matched ips. Desired # of ips are $service_container_count"
                                    fi
                                    break
                                else
                                    ip_forward=$(echo "${ipvsadm_response_array[index]}" | awk '{print $2}' | cut -f1 -d:)
                                    is_valid_ip=$(echo "$service_containers_string" | grep $service_name | awk '{print $4, $5}' | grep -c $ip_forward)
                                    if [ $is_valid_ip == "1" ]; then
                                        func_log_result "$SUCCESS_PREFIX" "On Server:$server; for NameSpace:$ns; for $match_string; $ip_forward is valid for service $service_name"
                                        containers_matched=$(($containers_matched + 1))
                                    else
                                        func_log_result "$FAILURE_PREFIX" "On Server:$server; for NameSpace:$ns; for $match_string; $ip_forward is not valid for service $service_name"
                                        containers_not_matched=$(($containers_not_matched + 1))
                                    fi
                                    
                                    # Processing last entry.
                                    if [ "$i" == "$ipvsadm_response_array_count" ]; then
                                        if [ "$containers_matched" = "$service_container_count" ]; then
                                            # All good ...
                                            func_log_result "$SUCCESS_PREFIX" "On Server:$server; for NameSpace:$ns; for service:$service_name; for $match_string; Next Mark Set Started. This mark set only has $containers_matched matching ips and $containers_not_matched un-matched ips. Desired # of ips are $service_container_count"
                                        else
                                            func_log_result "$FAILURE_PREFIX" "On Server:$server; for NameSpace:$ns; for service:$service_name; for $match_string; Next Mark Set Started. This mark set only has $containers_matched matching ips and $containers_not_matched un-matched ips. Desired # of ips are $service_container_count"
                                        fi
                                    fi
                                fi
                            done
                        fi
                    fi
                done
            done
        done
        
    done
}

function func_verify_services(){
    func_log_dtl "Verifying Services"
    unset service_state
    unset service_containers
    server=${active_servers[0]}
    current_test_step="VerifyServices"
    service_list_response=$(func_run_remote_simple_command "$server" "$LIST_SWARM_SERVICES")
    func_log_dtl "Services:$service_list_response"
    service_names=$(echo "$service_list_response" | grep -v IMAGE | awk '{print $2}')
    readarray -t service_name_array <<< "$service_names"
    for service in "${service_name_array[@]}"; do
        if [ -z "$service" ]; then
            func_log_dtl "Service is empty"
        else
            func_verify_service "$service"
        fi
    done
    
    service_state_string=$(printf -- '%s\n' "${service_state[@]}")
    service_containers_string=$(printf -- '%s\n' "${service_containers[@]}")
    func_log_dtl "Service State:$service_state_string"
    func_log_dtl "Service Containers state:$service_containers_string" 
    
    func_verify_iptables
}



function func_init_curl_tests(){

    unset server_curl_log_files_pids
    verification_ctx=$(uuidgen | sed 's/-//g' | cut -c 1-12)
    func_log_dtl "Verification Context:$verification_ctx"
    mkdir -p "$log_folder/curls"
    # run curl on all servers
    for server in "${active_servers[@]}"; do
        func_add_curl_for_server "$server" "$verification_ctx"
        #server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$api1_connectivity_log_file" "$api1_hostnames_log_file" "$api1_loadbalance_log_file" "$api2_connectivity_log_file" "$api2_hostnames_log_file" "$api2_loadbalance_log_file")
    done
}

function func_add_curl_for_server(){
    server=$1
    
    if [ -z "$2" ]; then
        verification_ctx=$(uuidgen | sed 's/-//g' | cut -c 1-12)
    else
        verification_ctx=$2
    fi
    api1_connectivity_log_file="$log_folder/curls/api1_connectivity_""$server""_$verification_ctx.log"
    while true; do curl -i -s --max-time 5 "http://$server" -H "host:test-api1.test.com" | head -n 1 | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api1_connectivity_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api1_connectivity_log_file")
    #pids=("${pids[@]}" "$!")

    api1_hostnames_log_file="$log_folder/curls/api1_hostname_""$server""_$verification_ctx.log"
    while true; do curl -s --max-time 5 "http://$server/hostname" -H "host:test-api1.test.com" | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api1_hostnames_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api1_hostnames_log_file")
    #pids=("${pids[@]}" "$!")

    api1_loadbalance_log_file="$log_folder/curls/api1_loadbalance_""$server""_$verification_ctx.log"
    while true; do curl -s --max-time 5 "http://$server" -H "host:test-api1.test.com" | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api1_loadbalance_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api1_loadbalance_log_file")
    #pids=("${pids[@]}" "$!")

    api2_connectivity_log_file="$log_folder/curls/api2_connectivity_""$server""_$verification_ctx.log"
    while true; do curl -i -s --max-time 5 "http://$server" -H "host:test-api2.test.com" | head -n 1 | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api2_connectivity_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api2_connectivity_log_file")
    #pids=("${pids[@]}" "$!")

    api2_hostnames_log_file="$log_folder/curls/api2_hostname_""$server""_$verification_ctx.log"
    while true; do curl -s --max-time 5 "http://$server/hostname" -H "host:test-api2.test.com" | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api2_hostnames_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api2_hostnames_log_file")
    #pids=("${pids[@]}" "$!")

    api2_loadbalance_log_file="$log_folder/curls/api2_loadbalance_""$server""_$verification_ctx.log"
    while true; do curl -s --max-time 5 "http://$server" -H "host:test-api2.test.com" | xargs echo "Server:$server Time:" $(date '+%Y-%m-%d.%H:%M:%S-%3N') >> "$api2_loadbalance_log_file"; sleep 1s; done &
    server_curl_log_files_pids=("${server_curl_log_files_pids[@]}" "$server $! $api2_loadbalance_log_file")
    #pids=("${pids[@]}" "$!")

}

function func_kill_curl_for_server(){
    server=$1
    for value in "${server_curl_log_files_pids[@]}"; do
        server_from_value=$(echo "$value" | awk '{print $1}')
        if [ "$server" == "$server_from_value" ]; then    
            pid=$(echo "$value" | awk '{print $2}')
            process_running_count=$(ps cax | grep -c "$pid")
            if [ "$process_running_count" -gt 0 ]; then
                func_log_dtl "Killing process:$pid"
                kill $pid
                wait $pid 2>/dev/null
            fi
        fi
    done
}

function func_kill_child_proccess(){
    # kill all process
    for value in "${server_curl_log_files_pids[@]}"; do
        pid=$(echo "$value" | awk '{print $2}')
        process_running_count=$(ps cax | grep -c "$pid")
        if [ "$process_running_count" -gt 0 ]; then
            func_log_dtl "Killing process:$pid"
            kill $pid
            wait $pid 2>/dev/null
        fi
    done
    #unset pids
}

function func_end_and_verify_curl_tests(){
    
    func_kill_child_proccess

    for value in "${server_curl_log_files_pids[@]}"; do
        curl_file=$(echo "$value" | awk '{print $3}')
        if [[ "$curl_file" == *"_connectivity_"* ]]; then
            func_log_dtl "Check file:$curl_file"
            success_count=$(grep -c "200 OK" "$curl_file")
            failure_count=$(grep -v -c "200 OK" "$curl_file")
            if [ "$failure_count" == 0 ]; then
                func_log_test_result "$SUCCESS_PREFIX" "Curl file:$curl_file has $success_count success and $failure_count failures."
            else
                failures=$(grep -v  "200 OK" $curl_file)
                func_log_test_result "$FAILURE_PREFIX" "Curl file:$curl_file has $success_count success and $failure_count failures."
                func_log_dtl "Failures are:$failures"
                
            fi 
        fi

    done
    unset server_curl_log_files_pids
}

function func_verify(){
    func_log "Verifying Test:$current_test_name; phase:$current_test_phase"
    func_verify_nodes "${desired_node_state[@]}"
    func_verify_services
}
