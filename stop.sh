#!/bin/bash

MACHINE="codeigniter"
HOSTS_TOKEN="codeigniter-dev"

# If we're not running on a linux machine, we need to be using docker-machine
if [ ${OSTYPE} != 'linux-gnu' ]; then
    eval $(docker-machine env ${MACHINE})
fi

echo  "Stopping containers."
docker-compose stop

echo  "Removing containers."
docker-compose rm -f

notice "Removing entries from hosts file."
sed "/# ${HOSTS_TOKEN}/d" /etc/hosts | sudo tee /etc/hosts > /dev/null

echo "Done uninstalling."
