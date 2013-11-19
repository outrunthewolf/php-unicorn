#!/usr/bin/env bash


docker_user="mattes" # if you dont want to use the default images
www_path=$(pwd)/www # where all your virtual hosts are
host_http_port="80" # make this port visible to your host machine
host_db_port="3306" # make this port visible to your host machine

# ------------



function usage {
  printf "Usage: docker.sh <path> <cmd>\n"
  printf "\nCommands:\n"
  printf "  create         Create Container\n"
  printf "  create-shell   Create and start shell in Container\n"
  printf "  kill           Stop and delete Container\n"
  printf "  re-create      Stop, delete and create new Container\n"
  printf "\nExamples:\n"
  printf "  ./docker.sh php/5.4 start\n"
  printf "  ./docker.sh http/apache start\n"
  printf "\n"
  printf "Please create web server (apache) containers\n"
  printf "AFTER PHP containers.\n\n"
}

path=$1
cmd=$2

if [[ $path == "" || $cmd == "" ]]; then
  usage && exit 1
fi

if [[ ! -e $path ]]; then
  printf "Error: path does not exist!\n" && usage && exit 1
fi

# replace / with - to create image name
image_name=${path/\//-}

# set defaults
expose_ports=""
share_dirs=""
link_containers=""

# config services ...
if [[ $path =~ "php" ]]; then
  php_fpm_port=$(echo $path | sed -e 's/[^0-9]*//g')
  expose_ports="-expose $php_fpm_port"
  share_dirs="-v $www_path:/www"
  link_containers="-link db-mysql:db"
  
elif [[ $path =~ "http" ]]; then
  expose_ports="-p $host_http_port:80"
  share_dirs="-v $www_path:/www"
  link_containers="-link php-5.3:php-5.3 -link php-5.4:php-5.4 -link php-5.5:php-5.5"

elif [[ $path =~ "db" ]]; then
  expose_ports="-p $host_db_port:3306"
fi


# commands ...
if [[ $cmd == "create" ]]; then
  docker run \
    $expose_ports \
    $share_dirs \
    $link_containers \
    -d \
    -name $image_name \
    $docker_user/$image_name

elif [[ $cmd == "create-shell" ]]; then
  docker run \
    $expose_ports \
    $share_dirs \
    $link_containers \
    -i -t \
    -name $image_name \
    $docker_user/$image_name \
    /bin/bash

elif [[ $cmd == "kill" ]]; then
  docker kill $image_name
  docker rm $image_name

elif [[ $cmd == "re-create" ]]; then
  ./docker.sh $path stop
  ./docker.sh $path start
fi