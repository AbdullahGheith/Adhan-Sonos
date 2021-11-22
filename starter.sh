#!/bin/bash

#install adhan time from api
if [[ $1 == "testtimes" ]];then 
		source /home/sonos_adhan.sh -times
elif [[ $1 == "testsonos" ]];then 
		source /home/sonos_adhan.sh -adhan
elif [[ $1 == "testpushover" ]];then 
		source /home/sonos_adhan.sh -pushover
else
		source /home/sonos_adhan.sh -install
		cd /home/node-sonos-http-api && npm start
fi
