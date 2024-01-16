#!/usr/bin/env bash

set -e
on_error(){
        echo "Error found in: $(caller)" >&2
}
 
trap 'on_error' ERR
 
#ls ~/dir_not_exists

cmd="ls -lrt ." 
cmd+=" & "
cmd+="mkdir new"
cmd_output=$(ls -lrt . && mkdir new 2>&1)
res=$?
echo $res
