#!/bin/bash

# Docker Machine name
MACHINE="codeigniter"
# Name of host
DOMAIN="codeigniter.dev"

# Colours
ESC_SEQ="\x1b["
COL_RESET=${ESC_SEQ}"39;49;00m"
COL_GREEN=${ESC_SEQ}"32;01m"
COL_YELLOW=${ESC_SEQ}"33;01m"
COL_RED=${ESC_SEQ}"31;01m"

# Common functions
function notice() {
    echo -e "${COL_GREEN}$1${COL_RESET}"
}

function create_machine() {
notice "Creating new machine"
    docker-machine create --driver virtualbox ${MACHINE}
}

function machine_setup() {
    # If we're not running on a linux machine, we need to be using docker-machine
    if [ ${OSTYPE} != 'linux-gnu' ]; then
        STATUS=$(docker-machine status ${MACHINE})

        # Check if the docker machine exists already, create one if not.
        if [[ $? == 1 ]]; then
            notice "No ${MACHINE} environment found"
            create_machine
        fi

        if [[ ${STATUS} == 'Stopped' ]]; then
            notice "Docker machine not running, starting now"
            docker-machine start ${MACHINE}
        fi

        if [[ ${STATUS} == 'Saved' ]]; then
            notice "Docker machine in saved state, restarting now"
            docker-machine start ${MACHINE}
        fi

        add_env
    fi

    docker_host_ip
}

function docker_host_ip() {
    if [ ${OSTYPE} != 'linux-gnu' ]; then
        DOCKER_HOST_IP=$(docker-machine ip ${MACHINE})
    else
        DOCKER_HOST_IP=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+' | head -1)
    fi
}

function add_env() {
    notice "Loading vars for docker machine"
    eval "$(docker-machine env ${MACHINE})"
}

function image_build() {
    if [[ "$(docker images -q $1 2> /dev/null)" == "" ]]; then
        docker build -t $1 dockerfiles/$1
    fi
}

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
./s
# If using docker-machine this corrects the xdebug remote host with your actual host ip not the docker-machine host ip.
if [ ${OSTYPE} != 'linux-gnu' ]; then
    LOCAL_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'| head -1)
    docker exec -it docker_codeigniter_1 sed -i "s/^xdebug\.remote_host=.*$/xdebug.remote_host=$LOCAL_IP/" /etc/php/mods-available/xdebug.ini
    docker exec -u root docker_codeigniter_1 apachectl graceful
fi

notice "Installing is complete you can now access the site : http://${DOMAIN}"