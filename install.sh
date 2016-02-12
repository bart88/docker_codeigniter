#!/bin/bash

sudo rm -rf hosts

# Colours
ESC_SEQ="\x1b["
COL_RESET=${ESC_SEQ}"39;49;00m"
COL_GREEN=${ESC_SEQ}"32;01m"
COL_YELLOW=${ESC_SEQ}"33;01m"
COL_RED=${ESC_SEQ}"31;01m"

# CREATE CODEIGNITER DIRECTORY

# ADD HOSTNAME

# RUN DOCKER COMPOSE

# REMOVE HOSTNAME



# Ensure the hosts file exists and is a file
sudo rm -rf hosts
touch hosts

machine_setup

# Build docker images that are used by containers through docker-compose.
# @TODO: Have these images prebuilt and available through docker registry would speed things up.
image_build "web"
image_build "dev"
image_build "uamariadb"

# Create empty vcl that will be populated when adding sites.
touch varnish/generated.vcl

# clone if directory doesn't exist
if [[ ! -d "code/ua-site-manager" ]]; then
    notice "Cloning repos to code/ directory ..."
    mkdir -p code
    git clone git@gitlab.adelaide.edu.au:web-team/keys.git code/keys
    chmod 0600 code/keys/ua_lamp_docker/id_rsa
    git clone git@gitlab.adelaide.edu.au:web-team/ua-site-manager.git code/ua-site-manager
    git clone git@gitlab.adelaide.edu.au:web-team/ua-docker-build-server-scripts.git code/ua-docker-build-server-scripts
else
    cd code/keys
    git pull
    cd ../ua-site-manager
    git pull
    cd ../..
fi

cp code/keys/credentials.xml dockerfiles/uajenkins/files/credentials.xml
image_build "uajenkins"

clean_hosts

# Detect if DNS has already been setup for the desired domain setting above
HOST_IP=$(host -t a site-manager.${DOMAIN} | awk '{ print $4 }')
if [ "${HOST_IP}" != "${DOCKER_HOST_IP}" ]; then
    notice "Adding host file entries for ${DOMAIN}"
    for i in www www.site-manager site-manager www.jenkins jenkins www.registry registry www.mail mail; do
        echo "${DOCKER_HOST_IP} ${i}.${DOMAIN} # ua-docker-dev" | sudo tee -a /etc/hosts
    done
    echo "${DOCKER_HOST_IP} ${DOMAIN} # ua-docker-dev" | sudo tee -a /etc/hosts
fi

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

notice "Setting app permissions."
sudo chmod -R 777 code/ua-site-manager/app/sites/
docker exec -u root docker_jenkins_1 chown -R 1000:1000 /var/jenkins_home/

if [ ${OSTYPE} != 'linux-gnu' ]; then
    # Add the ua_lamp_docker pub key to docker-machine default authorized keys so we can ssh into it from jenkins.
    cat code/keys/ua_lamp_docker/id_rsa.pub | docker-machine ssh default "cat >> ~/.ssh/authorized_keys"
fi

# remove the key - add to agent
SSH_CMD="ssh -p 2222 root@${DOMAIN} -i code/keys/ua_lamp_docker/id_rsa  -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -o ForwardAgent=yes"

notice "Waiting for mysql to settle."
sleep 15

create_hosts_file

# If using docker-machine then copy hosts file
if [ ${OSTYPE} != 'linux-gnu' ]; then
  docker-machine scp hosts ${MACHINE}:~/hosts
  docker-machine ssh ${MACHINE} 'sudo mv hosts /etc/hosts'
fi

notice "Building sites."
${SSH_CMD} "cd /code/ua-site-manager && robo build"

notice "Setting app permissions, again."
sudo chmod -R 777 code/ua-site-manager/app/sites/

notice "\nInstalling is complete! site is at http://site-manager.${DOMAIN}"
notice "You can access the dev server with:"
notice "${SSH_CMD}"

# If using docker-machine this corrects the xdebug remote host with your actual host ip not the docker-machine host ip.
if [ ${OSTYPE} != 'linux-gnu' ]; then
    LOCAL_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'| head -1)
    docker exec -it docker_uasm_1 sed -i "s/^xdebug\.remote_host=.*$/xdebug.remote_host=$LOCAL_IP/" /etc/php/mods-available/xdebug.ini
    docker exec -u root docker_uasm_1 apachectl graceful
fi
