#!/bin/bash

function check_package_installed(){
    if dpkg --get-selections | grep -q "^$1[[:space:]]*install$" >/dev/null; then
        return 0
    else
        return 1
    fi
}
package_to_check=ipvsadm
if check_package_installed $package_to_check; then
    echo "$package_to_check is already installed"
else
    echo "Installing $package_to_check"
    apt-get update
    apt-get install $package_to_check
fi

if [ ! -f ./nsenter ]; then
    echo "File ./nsenter does not exists. Installing nsenter"
    docker run --rm jpetazzo/nsenter cat /nsenter > ./nsenter &&  sudo chmod +x ./nsenter
fi
