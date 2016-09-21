#!/bin/bash

# include files
. constants.sh
. logging.sh
. remote-execute.sh
. verify.sh
. server-setup.sh
. server-upgrade-test.sh
. drain-test.sh
. unplanned-failure-test.sh
. scale-up-down-test.sh

uninstall_docker=${UNINSTALL_DOCKER:-false}
install_docker=${INSTALL_DOCKER:-false}
docker_version_to_install=${DOCKER_VERSION:-}
service_setup=${SERVICE_SETUP:-true}
run_scale_up_down_test=${RUN_SCALE_UP_DOWN_TEST:-true}
run_drain_test=${RUN_DRAIN_TEST:-true}
run_server_upgrade_test=${RUN_SERVER_UPGRADE_TEST:-true}
run_unplanned_shutdown_test=${RUN_UNPLANNED_SHUTDOWN_TEST:-true}
user_name=${SSH_USER_NAME:-}
password=${SSH_PASSWORD:-}
server_string=${SERVERS:-}

tmp_file="swarm_test_tmp_file.sh"

dtl_log_file=""
summary_log_file=""
current_test_name=""
current_test_phase=""
current_test_step=""
declare -a current_test_results
#current_test_results=""
current_test_success_counter=0
current_test_failure_counter=0
current_test_warning_counter=0
#all_test_summary=""
declare -a all_test_summary_results
log_folder=""

declare -a servers
declare -a servers_node_id_map
declare -a active_servers
declare -a service_containers
declare -a service_state

declare -a pids
declare -a server_curl_log_files_pids



function func_add_summary_results(){
    #func_log ""
    total_test=$(($current_test_success_counter + $current_test_failure_counter + $current_test_warning_counter))
    summary_message="Results for Test:$current_test_name; Total:$total_test; SUCCESS:$current_test_success_counter; WARNING:$current_test_warning_counter; FAIL: $current_test_failure_counter"
    all_test_summary_results=("${all_test_summary_results[@]}" "$summary_message")
}



function func_init_test(){
    func_init_curl_tests
    func_reset_test_counters
}

function func_print_result_summary(){
    result_summary_string=$(printf -- '%s\n' "${all_test_summary_results[@]}")
    echo ""
    func_log "Summary of Results:"
    func_log "$result_summary_string"
}

function func_end_test(){
    func_end_and_verify_curl_tests
    func_add_summary_results
}


function func_reset_test_counters(){
    current_test_failure_counter=0
    current_test_success_counter=0
    current_test_warning_counter=0
    unset current_test_results
}


function func_build_server_node_id_map(){
    for server in "${servers[@]}"; do
        node_id=$(func_run_remote_simple_command "$server" "$GET_CURRENT_NODE_ID")
        servers_node_id_map=("${servers_node_id_map[@]}" "$server $node_id")
    done
    servers_node_id_map_string=$(printf -- '%s\n' "${servers_node_id_map[@]}")
    func_log_dtl "Server Map:$servers_node_id_map_string"
}

function func_set_default_desired_state(){
    unset desired_node_state
    unset active_servers
    for server in "${servers[@]}"; do
        node_id=$(echo "$servers_node_id_map_string" | grep "$server" | awk '{print $2}')
        desired_node_state=("${desired_node_state[@]}" "$node_id Ready Active 'Leader\|Reachable'")
        active_servers=("${active_servers[@]}" "$server")
    done
}

function func_initial_setup(){
    
    if [ "$service_setup" == "true" ]; then
        func_log "Setting up services"
        command=$(cat service-setup.sh)
        server=${active_servers[0]}
        func_run_remote_command "$server" "$command"
        func_log "Service Setup Completed. Sleeping for 120s"
        sleep 120s
    fi

    current_test_name="InitialSetup"
    current_test_phase="PostSetupVerify"
    #func_log "Verifying initial setup"
    func_set_default_desired_state
    func_init_test
    func_verify
    func_end_test
}






func_init_logging
func_log "Log File Summary: $summary_log_file"
func_log "Log File Details: $dtl_log_file"

function func_init_active_servers(){
    unset active_servers
    unset servers
    oldifs="$IFS"
    IFS=",";
    for server in $(echo "$server_string"); do
        servers=("${servers[@]}" "$server")
        active_servers=("${active_servers[@]}" "$server")
    done
    IFS="$oldifs"
    for server in "${servers[@]}"; do
        func_run_remote_simple_command "$server" "echo 'Connected to server:$server'"
    done
    

}

func_init_active_servers

if [ "$uninstall_docker" == "true" ]; then
    func_uninstall_docker
else
    func_log "Uninstall is not enabled"
fi

if [ "$install_docker" == "true" ]; then
    func_install_docker
else
    func_log "Install Docker is not enabled"
fi



func_setup_ipvsadm_nsenter

func_build_server_node_id_map

func_initial_setup


if [ "$run_scale_up_down_test" == "true" ]; then
    func_scale_up_down_test
fi
if [ "$run_drain_test" == "true" ]; then
    func_drain_test
fi
if [ "$run_server_upgrade_test" == "true" ]; then
    func_upgrade_test
fi
if [ "$run_unplanned_shutdown_test" == "true" ]; then
    func_unplanned_failure_test
fi

func_log "Test finished."

func_print_result_summary




