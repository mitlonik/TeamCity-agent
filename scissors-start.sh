#!/bin/bash
#A scissors start script
#This script is run whenever you push your code
# EXTRA_ARGS args required by scissors.  At present this includes -name and -cidfile
# working directory = your source code

if [ -a ../config ]; then
	rm -rf ../config
fi
mkdir -p ../config
ABSPATH=$(pwd)/../config

docker run $EXTRA_ARGS -p 9000 -v $ABSPATH:/config -d $IMAGE_NAME
CONTAINER=$(cat ../CONTAINER_ID)

# we have to work around https://github.com/dotcloud/docker/issues/3778
#so what we do is use a docker volume to create files called "port" and "hostname" that contain the correct values
#the docker image (in start_agent.sh) waits for these and reconfigures the agent before booting
PORT=$(docker port $CONTAINER 9000 | sed 's/.*://')
NAME=$(docker ps | grep c54347f0c225 | tr -s ' ' | cut -d ' ' -f 12)
echo $NAME > ../config/hostname
echo $PORT > ../config/port
sudo ufw allow $PORT
