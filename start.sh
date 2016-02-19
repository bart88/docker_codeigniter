#!/bin/bash

. common.sh

get_projectdir

machine_setup

# CREATE CODEIGNITER DIRECTORY
if [[ ! -d "codeigniter" ]]; then
    notice "Creating a codeigniter directory"
    mkdir -p codeigniter
    git clone git@github.com:bcit-ci/CodeIgniter.git
fi

# ADD DOMAIN and IP TO HOSTS
HOST_IP=$(host -t a ${DOMAIN} | awk '{ print $4 }')
if [ "${HOST_IP}" != "${DOCKER_HOST_IP}" ]; then
    notice "Adding host file entries for ${DOMAIN}"
    echo "${DOCKER_HOST_IP} ${DOMAIN} # codeigniter-dev" | sudo tee -a /etc/hosts
fi

# BUILD OUR DOCKER IMAGES
image_build "codeigniter"
image_build "mariadb"

# RUN DOCKER COMPOSE
notice "Running docker-compose build."
docker-compose build
if [ $? != 0 ]; then
    error "Building failed"
    exit
fi

notice "Running docker-compose up."
docker-compose up -d
if [ $? != 0 ]; then
    error "Bringing sites up failed"
    exit
fi

# If using docker-machine this corrects the xdebug remote host with your actual host ip not the docker-machine host ip.
if [ ${OSTYPE} != 'linux-gnu' ]; then
    LOCAL_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'| head -1)
    docker exec -it cidocker_codeigniter_1 sed -i "s/^xdebug\.remote_host=.*$/xdebug.remote_host=$LOCAL_IP/" /etc/php/mods-available/xdebug.ini
    docker exec -u root cidocker_codeigniter_1 apachectl graceful
fi

notice "Installing is complete you can now access the site : http://${DOMAIN}"