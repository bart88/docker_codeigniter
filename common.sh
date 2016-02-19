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


function get_projectdir() {
    PROJECTDIR=`basename $(pwd) | sed 's/[-_]//g'`
}
