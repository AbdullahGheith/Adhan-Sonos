#!/bin/bash

#source "/home/sonos_adhan.cfg" 

#send push notification with pushover
function AdhanPush() {
	if [[ $pushover_notifications = true ]]
		then
			echo $user_token | sed -n 1'p' | tr ',' '\n' | while read word; do
			#get data from config file
				wget https://api.pushover.net/1/messages.json --post-data="token=$app_token&user=$word&message=$2&title=$1" -q
			done
	fi
}
#get prayer times based on location from config file via API aladhan.com
function AdhanTimes() {

	url=$(curl -s "http://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$method" -L)
	#make a list of 5 prayes	
	declare -a arr=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
		#create a loop so each prayer gets a crontab
		for i in "${arr[@]}"
		do	
			#get the times from api
			pray=$(jq -r  '.data.timings.'$i <<< "${url}" ) 
			command="/bin/bash /home/sonos_adhan.sh -adhan; cat /etc/crontabs/root | grep -v DELETEME-${i,} > /etc/crontabs/root.temp; cat /etc/crontabs/root.temp > /etc/crontabs/root"
			job="${pray:3:2} ${pray:0:2} * * * $command"
			echo "$job" >> /etc/crontabs/root
			#cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab
			#create array message for push
			message+=($i" "$pray)
			
			if [ $adhan_preannounce_minutes -gt 0 ] 
				then
					command="/bin/bash /home/sonos_adhan.sh -preannounce; cat /etc/crontabs/root | grep -v DELETEMEPRE-${i,} > /etc/crontabs/root.temp; cat /etc/crontabs/root.temp > /etc/crontabs/root"
					newTime=$(dateadd "${pray:0:2}:${pray:3:2}" -"$adhan_preannounce_minutes"m)
					prejob="${newTime:3:2} ${newTime:0:2} * * * $command"
					
					echo "$prejob" >> /etc/crontabs/root
					#cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$prejob") | crontab
			fi
			
		done
}
#get prayer times based on location from config file via API aladhan.com
function AdhanTimesShow() {

	url=$(curl -s "https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$method" -L)
	#make a list of 5 prayes	
	declare -a arr=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
		#create a loop so each prayer gets a crontab
		for i in "${arr[@]}"
		do	
			pray=$(jq -r  '.data.timings.'$i <<< "${url}" ) 
			printf "$i $pray"
			echo -e "\n"
		done
}

#trigger at every midnight to refresh times.
function refreshTimes(){
	echo -e "BASH_ENV=/home/container.env\n\n0 0 * * * /bin/bash /home/sonos_adhan.sh -install\n" > /etc/crontabs/root
	#(crontab -l ; echo "0 0 * * * /bin/bash /home/sonos_adhan.sh -install" ) | crontab
}

function sonosPlayAdhan(){
	if [ $speaker = "chromecast" ] 
		then
		go-chromecast volume "0.$1" -a "$chromecastip" 2>&1 &
		go-chromecast load http://"$hostip":6006/azan.mp3 -a "$chromecastip" 2>&1 &
	else
		curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$1"
	fi
	
}

function sonosSay(){
	if [ $speaker = "chromecast" ] 
		then
			go-chromecast volume "0.$2" -a "$chromecastip" 2>&1 &
			gtts-cli "$1" -t dk -l da --output /home/node-sonos-http-api/static/clips/tts.mp3
			go-chromecast load http://"$hostip":6006/tts.mp3 -a "$chromecastip" 2>&1 &
		else
		#replace space by url friendly space
		adhan_preannounce_text_format=${1// /%20}
		curl --silent --output /dev/null http://localhost:5005/sayall/"$adhan_preannounce_text_format"/"$language"/"$2"
	fi
	
}

function getVolume() {
	if [[ "$(date +%H)" > $adhan_time_day ]]
		then
			eval $1=$adhan_volume_day
		else
			eval $1=$adhan_volume_night
		fi
}

function AdhanPreannounce() {
#check is adhan is active
	if [[ $active = true ]]
		then 
		
		#check current hour for volume
		getVolume newvol
		
		if [[ $adhan_preannounce = true ]]
			then 
			sonosSay "$adhan_preannounce_text" $newvol
		fi
		
	fi
	#send notification
	if [[ $salah_notification_salah = true ]]
		then 
			AdhanPush "Salah" "Preannounce salah $newvol"
	fi
}

function AdhanPlay(){
	#check is adhan is active
	if [[ $active = true ]]
		then 
		
		#check current hour for volume
		getVolume newvol
		
		if [[ $adhan_preannounce = true ]]
			then 
			#if minutes delay = 0, then say preannouncement. Anything greater than that is scheduled for cron
			if [ $adhan_preannounce_minutes -eq 0 ]
				then
				sonosSay "$adhan_preannounce_text" $newvol
			fi
		fi
		
		sonosPlayAdhan $newvol
			
	fi
	#send notification
	if [[ $salah_notification_salah = true ]]
		then 
			AdhanPush "Salah" "It's time to pray $newvol"
	fi
}
#install adhan time from api
if [[ $1 == -install ]];then 
		refreshTimes
		AdhanTimes
elif [[ $1 == -times ]];then 
		AdhanTimesShow
#play the adhan
elif [[ $1 == -adhan ]];then	
		AdhanPlay
		sleep 1m
elif [[ $1 == -preannounce ]];then	
		AdhanPreannounce
elif [[ $1 == -pushover ]];then	
		AdhanPush "SonosAdhan" "Testsuccessful"
		printf "Notification sent"
fi
