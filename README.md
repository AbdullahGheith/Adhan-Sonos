 #Current status: NOT WORKING - cron jobs are not executing inside the docker for some reason
 # sonos_adhan_docker

This is originally a script made by joohan: https://github.com/joohann/Adhan-Sonos

I fixed it and made it into a docker container for easier setup.

# build

You can either use the config file, or you can enter the variables directly into the run command.

If you want to build the image yourself, and use the cfg file, you have to go to sonos_adhan.sh and remove the comment (# symbol) on line 3 "source "/home/sonos_adhan.cfg"

to build, just build it as usually using:

```
git clone https://github.com/AbdullahGheith/sonos_adhan_docker.git
cd sonos_adhan_docker
docker build . -t adhan
```

# run

If you havent built it yourself, you can run it directly from docker hub:

```
docker run -e pushover_notifications=true -e app_token=kjdnckndmvmfpmvfvmomfmfdm -e user_token=fpoofemoimoimvomdkrkedfd -e salah_notification_salah=false -e active=true -e city=breukelen -e country=nl -e method=3 -e language=en-us -e adhan_time_day=10:00 -e adhan_volume_day=30 -e adhan_time_night=22:00 -e adhan_volume_night=5 -e adhan_preannounce=false -e adhan_preannounce_text="It is time to pray" -e adhan_preannounce_minutes=10 --restart unless-stopped -it -d -p 5005:5005 xabdullahx/adhan-sonos
```

If you are building it yourself and are using the cfg file, you probably know how to run it:

```
docker run -d -it --restart unless-stopped -p 5005:5005 adhan
```

Run your docker run with this command to make sure it autostars when server is restarted
```
--restart unless-stopped
```

# config

If you are not sure what your settings are supposed to be, you can run the contianer with the "testtimes" command. This way it will only print the times and not run any container. i.e:

```
docker run -e pushover_notifications=true -e app_token=kjdnckndmvmfpmvfvmomfmfdm -e user_token=fpoofemoimoimvomdkrkedfd -e salah_notification_salah=false -e active=true -e city=breukelen -e country=nl -e method=3 -e language=en-us -e adhan_time_day=10:00 -e adhan_volume_day=30 -e adhan_time_night=22:00 -e adhan_volume_night=5 -e adhan_preannounce=false -e adhan_preannounce_text="It is time to pray" -e adhan_preannounce_minutes=10 -it -p 5005:5005 xabdullahx/adhan-sonos testtimes
```

"testsonos" to check that the container can play azan correctly.
"testpushover" is to check if pushover is working correctly

The rest of the configs (env variables) can be seen below: 

| Config                     | Meaning                                                                                                                     |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| pushover_notifications     | true/false. Set if pushover is active.                                                                                      |
| app_token                  | Used for pushover.net. Can send notifications to your phone when its salah time                                             |
| user_token                 | Used for pushover.net. Can send notifications to your phone when its salah time                                             |
| salah_notification_install | Get notification from pushover when this container is running                                                               |
| active                     | true/false value. Determines if adhan should be played through sonos speakers.                                              |
| city                       | City to use for azan. More info: https://aladhan.com/prayer-times-api - Scroll down to the TimingsByCity endpoint           |
| country                    | Country to use for azan. More info: https://aladhan.com/prayer-times-api - Scroll down to the TimingsByCity endpoint        |
| method                     | Salah times calculation method. More info: https://aladhan.com/prayer-times-api - Scroll down to the TimingsByCity endpoint |
| language                   | Language used for preannouncement                                                                                           |
| adhan_time_day             | Set when is "day". Used for the determining volume while playing adhan                                                      |
| adhan_volume_day           | Volume through "day"                                                                                                        |
| adhan_time_night           | Set when is "night". Used for determining volume while playing adhan                                                        |
| adhan_volume_night         | Volume through "night"                                                                                                      |
| adhan_preannounce          | Preannounce adhan before it starts                                                                                          |
| adhan_preannounce_text     | What the speakers will say to preannounce adhan                                                                             |
| adhan_preannounce_minutes  | Integer value. How many minutes before adhan to remind you about current salah time is ending.                              |

**Notice that there are no default settings, so all settings must be provided**
