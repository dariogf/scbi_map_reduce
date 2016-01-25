#!/usr/bin/env bash

# script to launch workers with bash
# it needs to initialize ruby environment, cd to working dir, and 
# get path

# function canonpath ()
# { 
#     echo $(cd $(dirname $1); pwd -P)/$(basename $1)
# }

absolute_path="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"

# absolute_path=canonpath $0;
echo Absolute path: $absolute_path
echo Launching at HOST:
hostname
echo With user:
whoami

main_worker_path=`dirname $absolute_path`


echo $main_worker_path
if [ ! "$#" -eq "6" ] && [ ! "$#" -eq "5" ]; then
    echo "Only $# parameters provided"
    echo "Usage: $0 worker_id server_ip server_port worker_file init_dir init_file"
    exit;
fi

worker_id=$1;
server_ip=$2;
server_port=$3;
worker_file=$4;
init_dir=$5;
init_file=$6;
echo "Launching worker: $worker_id"

if [ $init_file ] && [ -e $init_file ]; then
    echo "Initializing env"
    source $init_file;
fi

if [ -e $init_dir ]; then
    echo "Changing to $init_dir"
    cd $init_dir;
fi



echo Launching: ${main_worker_path}/main_worker.rb $worker_id $server_ip $server_port $worker_file

${main_worker_path}/main_worker.rb $worker_id $server_ip $server_port $worker_file