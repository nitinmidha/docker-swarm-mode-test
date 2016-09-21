#!/bin/bash

function func_init_logging(){
    # generate a random 12 char string
    random_str=$(uuidgen | sed 's/-//g' | cut -c 1-12)
    log_folder="/var/log/swarm-test/$random_str"
    mkdir -p "$log_folder"
    dtl_log_file="$log_folder/details.log"
    summary_log_file="$log_folder/summary.log"
}


function func_log_test_result(){
    result=$1
    shift
    message="Test:$current_test_name; Result:$result; message:$@"
    if [ "$result" == "$SUCCESS_PREFIX" ]; then
        current_test_success_counter=$(($current_test_success_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        func_log_dtl "$message"
    elif [ "$result" == "$FAILURE_PREFIX" ]; then
        current_test_failure_counter=$(($current_test_failure_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        echo ""
        func_log "$message"
    elif [ "$result" == "$WARN_PREFIX" ]; then
        current_test_warning_counter=$(($current_test_warning_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        echo ""
        func_log "$message"
    else
        func_log_dtl "Unknown first argument:$result. Other arguments are $@"
    fi
}


function func_log_result(){
    result=$1
    shift
    message="Test:$current_test_name; Phase:$current_test_phase; Step:$current_test_step; Result:$result; message:$@"
    if [ "$result" == "$SUCCESS_PREFIX" ]; then
        current_test_success_counter=$(($current_test_success_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        func_log_dtl "$message"
    elif [ "$result" == "$FAILURE_PREFIX" ]; then
        current_test_failure_counter=$(($current_test_failure_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        echo ""
        func_log "$message"
    elif [ "$result" == "$WARN_PREFIX" ]; then
        current_test_warning_counter=$(($current_test_warning_counter + 1))
        current_test_results=("${current_test_results[@]}" "$message")
        echo ""
        func_log "$message"
    else
        func_log_dtl "Unknown first argument:$result. Other arguments are $@"
    fi
}

function func_log(){
    curr_date=$(date '+%Y-%m-%d.%H:%M:%S-%3N')
    #echo
    #echo on console
    echo  "$curr_date" "$*"
    # log in summary_file
    echo "$curr_date" "$*" >> $summary_log_file
    #log in detail file
    echo "$curr_date" "$*" >> $dtl_log_file
}

function func_log_dtl(){
    curr_date=$(date '+%Y-%m-%d.%H:%M:%S-%3N')
    # log in summary_file
    #echo "$curr_date" "$*" >> $summary_log_file
    #log in detail file
    echo "$curr_date" "$*" >> $dtl_log_file
}