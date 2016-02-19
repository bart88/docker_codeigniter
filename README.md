## DOCKERISED CODEIGNITER 
#### A development environment for codeigniter developers

### How to Install

#### Mac OS / Linux / Unix
If you are **Mac OS X** user you will need to install the [docker toolbox](https://www.docker.com/products/docker-toolbox). This will come with the docker-machine ( a light-weight virtual machine to run your docker containers in ), the docker client and docker compose.  

**Linux** 

[Install docker](https://docs.docker.com/linux/step_one/)

[Install docker compose](https://docs.docker.com/engine/installation/linux/ubuntulinux/)

##### Building / Starting

```bash
./start.sh
```
###### How it works

The bash script builds and brings up the 2 containers defined in the ```docker-compose.yml``` based on the ```Dockerfile``` for each named container. The script also pulls the ip address of the apache container and writes to your hosts file so the host ```codeigniter.dev``` is accessible. On stopping the containers all entries added to the hosts file are removed this is done by token added to each entry.

##### Stopping 

```bash
./stop.sh
```

##### Destroying the environment
**Remove all images**
```bash
docker rmi $(docker images -q)
```

**Stop and remove the docker-machine ( Mac OS X only)**

```bash
docker-machine stop codeigniter
docker-machine rm codeigniter
```


#### Windows 
Sorry windows people :-(

**TODO TASKS**
- [ ]   Figure out how to Docker on Windows  
- [ ]   Convert bash scripts into something portable
- [ ]   Write better docs

