#!/bin/bash
while true
do
	echo "Waiting for port..."

	if [ -f /config/port ]; then
		echo "got port"
		break
	fi
	sleep 1
done

while true
do
	echo "Waiting for hostname..."
	if [ -f /config/hostname ]; then
		break
	fi
	sleep 1
done

PORT=$(cat /config/port)
sed -i "s/ownPort=.*/ownPort=$PORT/g" buildAgent/conf/buildAgent.properties

HOSTNAME=$(cat /config/hostname)
sed -i "s/name=.*/name=$HOSTNAME/g" buildAgent/conf/buildAgent.properties


bash buildAgent/bin/agent.sh run