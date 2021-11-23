FROM node:lts

RUN apt-get -qq update
RUN apt-get -qq install nano
RUN apt-get -qq install git
RUN apt-get -qq install jq
RUN apt-get -qq install cron
RUN apt-get -qq install python3-pip
RUN pip3 install gTTS

COPY sonos_adhan.sh sonos_adhan.cfg starter.sh initchromecast.sh /home/
RUN chmod +x /home/sonos_adhan.sh 
RUN chmod +x /home/starter.sh 
RUN chmod +x /home/initchromecast.sh 

WORKDIR /home

RUN ./initchromecast.sh
RUN git clone https://github.com/jishi/node-sonos-http-api.git
COPY azan.mp3 /home/node-sonos-http-api/static/clips/

WORKDIR /home/node-sonos-http-api
RUN npm install --production
RUN npm install http-server -g

WORKDIR /home

ENTRYPOINT ["/home/starter.sh"]
