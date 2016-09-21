#!/bin/bash


function func_run_remote_simple_command(){
    #echo "Running:$2"
    func_log_dtl "Running:$2 on $1"
    #sshpass -p $password ssh $user_name@$1 "echo $password | sudo -S $2"
    ssh -o StrictHostKeyChecking=no $user_name@$1 "echo $password | sudo -S $2"
}

function func_run_remote_command(){
    server="$1"
    func_log_dtl "Running:$2 with args $3 $4 $5 on $server server"
    echo "$2" > $tmp_file && chmod +x "$tmp_file"
    #sshpass -p $password scp  $tmp_file $user_name@$server:~/
    scp  $tmp_file $user_name@$server:~/ 
    #sshpass -p $password ssh  $user_name@$server "echo $password | sudo -S ./$tmp_file $3 $4 $5" >> $dtl_log_file
    ssh -o StrictHostKeyChecking=no  $user_name@$server "echo $password | sudo -S ./$tmp_file $3 $4 $5" >> $dtl_log_file
}
