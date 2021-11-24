#!/bin/bash

#install adhan time from api
if [[ $1 == "testtimes" ]];then 
		source /home/sonos_adhan.sh -times
elif [[ $1 == "testsonos" ]];then 
		source /home/sonos_adhan.sh -adhan
elif [[ $1 == "testpushover" ]];then 
		source /home/sonos_adhan.sh -pushover
else
		if [ $speaker = "chromecast" ] 
		then
			declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /home/container.env
			http-server /home/node-sonos-http-api/static/clips -p 6006 > http.log 2>&1 &
		fi
		service cron start
		source /home/sonos_adhan.sh -install
		cd /home/node-sonos-http-api && npm start
fi
