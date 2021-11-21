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
	(crontab -l ; echo "0 0 * * * bin/bash /home/sonos_adhan.sh -install") | crontab
}

function AdhanPlay(){
	#check is adhan is active
	if [[ $active = true ]]
		then 
		
		#check current hour for volume
		if [[ "$(date +%H)" > $adhan_time_day ]]
		then
			if [[ $adhan_preannounce = true ]]
				then 
					#replace space by url friendly space
					adhan_preannounce_text_format=${adhan_preannounce_text// /%20}
					curl --silent --output /dev/null http://localhost:5005/sayall/"$adhan_preannounce_text_format"/"$language"/"$adhan_volume_day"
					curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$adhan_volume_day"
			else
					curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$adhan_volume_day"
			fi

		#if it's night
		else
			if [[ $adhan_preannounce = true ]]
				then 
					#replace space by url friendly space
					adhan_preannounce_text_format=${adhan_preannounce_text// /%20}
					curl --silent --output /dev/null http://localhost:5005/sayall/"$adhan_preannounce_text_format"/"$language"/"$adhan_volume_night"
					curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$adhan_volume_night"
			else
					curl --silent --output /dev/null --connect-timeout 560 http://localhost:5005/clipall/azan.mp3/"$adhan_volume_night"
			fi
		fi
	fi
	#send notification
	if [[ $salah_notification_salah = true ]]
		then 
			AdhanPush "Salah" "It's time to pray"
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
elif [[ $1 == -pushover ]];then	
		AdhanPush "SonosAdhan" "Testsuccessful"
		printf "Notification sent"
fi
