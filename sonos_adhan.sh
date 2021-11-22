#!/bin/bash

#source "/home/sonos_adhan.cfg" 

#send push notification with pushover
function AdhanPush() {
	if [[ $pushover_notifications = true ]]
		then	
			#get data from config file
			 wget https://api.pushover.net/1/messages.json --post-data="token=$app_token&user=$user_token&message=$2&title=$1" -q
	fi
}
#get prayer times based on location from config file via API aladhan.com
function AdhanTimes() {

	url=$(curl -s "http://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$method")
	#make a list of 5 prayes	
	declare -a arr=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
		#create a loop so each prayer gets a crontab
		for i in "${arr[@]}"
		do	
			#get the times from api
			pray=$(jq -r  '.data.timings.'$i <<< "${url}" ) 
			command="/bin/bash /home/sonos_adhan.sh -adhan; crontab -l | grep -v DELETEME-${i,} | crontab"
			job="${pray:3:4} ${pray:0:2} * * * $command"
			cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab
			#create array message for push
			message+=($i" "$pray)
			
			if [ $adhan_preannounce_minutes -gt 0 ] 
				then
					command="/bin/bash /home/sonos_adhan.sh -preannounce; crontab -l | grep -v DELETEMEPRE-${i,} | crontab"
					newTime=$(date --date "${pray:0:2}:${pray:3:4}:30 $(date +"%Z")  -$adhan_preannounce_minutes min")
					newMin=$(date --date="$newTime" '+%M')
					newHour=$(date --date="$newTime" '+%H')
					prejob="$newMin $newHour * * * $command"
					
					cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$prejob") | crontab
			fi
			
		done
}
#get prayer times based on location from config file via API aladhan.com
function AdhanTimesShow() {

	url=$(curl -s "https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$method")
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
	(crontab -l ; echo "0 0 * * * /bin/bash /home/sonos_adhan.sh -install") | crontab
}

function adhanPrenounce(){
	if [[ "$(date +%H)" > $adhan_time_day ]]
		then
			newvol=$adhan_volume_day
		else
			newvol=$adhan_volume_night
	fi
	
	sonosSay $adhan_preannounce_text $newvol
}

function sonosPlayAdhan(){
	curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$1"
}

function sonosSay(){
	#replace space by url friendly space
	adhan_preannounce_text_format=${1// /%20}
	curl --silent --output /dev/null http://localhost:5005/sayall/"$adhan_preannounce_text_format"/"$language"/"$2"
	curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$2"
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
			sonosSay $adhan_preannounce_text $newvol
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
			if [$adhan_preannounce_minutes -eq 0]
				then
				sonosSay $adhan_preannounce_text $newvol
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
		crontab -r
		AdhanTimes
		refreshTimes
elif [[ $1 == -times ]];then 
		AdhanTimesShow
#play the adhan
elif [[ $1 == -adhan ]];then	
		AdhanPlay
elif [[ $1 == -preannounce ]];then	
		AdhanPreannounce
elif [[ $1 == -pushover ]];then	
		AdhanPush "SonosAdhan" "Testsuccessful"
		printf "Notification sent"
fi
