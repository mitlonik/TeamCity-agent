#!/bin/bash
#A scissors start script
#This script is run whenever you push your code
# EXTRA_ARGS args required by scissors.  At present this includes -name and -cidfile
# working directory = your source code

if [ -a ../config ] then;
	rm -rf ../config
fi
mkdir -p ../config
ABSPATH=$(pwd)/../config

docker run $EXTRA_ARGS -p 9000 -v $ABSPATH:/config $IMAGE_NAME
CONTAINER=$(cat ../CONTAINER_ID)

PORT=$(docker port $CONTAINER 8111 | sed 's/.*://')
NAME=$(docker ps | grep c54347f0c225 | tr -s ' ' | cut -d ' ' -f 12)
echo $NAME > ../config/hostname
echo $PORT > ../config/port
sudo ufw allow $PORT
