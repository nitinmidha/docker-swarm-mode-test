#!/bin/bash

function func_scale_up_down_test(){
    func_log "Scale Up/Down test. We will randomly scale services and verify."
    current_test_name="Scale Test"
    func_set_default_desired_state
    func_init_test
    server="${active_servers[0]}"
    for i in $(seq 1 4); do
        random_number_1=$(($RANDOM % 10 + 1))
        random_number_2=$(($RANDOM % 10 + 1))
        current_test_phase="Iteration $i"
        command="$SERVICE_SCALE test-api1=$random_number_1 test-api2=$random_number_2"
        
        func_run_remote_simple_command "$server" "$command"
        func_log "Scalled Services test-api1=$random_number_1 test-api2=$random_number_2. Sleeping for 120s for changes to take effect."
        sleep 120s
        func_verify 
    done
    func_end_test
}