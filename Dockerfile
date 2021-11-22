FROM node:lts

RUN apt-get -qq update
RUN apt-get -qq install nano
RUN apt-get -qq install git
RUN apt-get -qq install jq
RUN apt-get -qq install cron

COPY sonos_adhan.sh sonos_adhan.cfg starter.sh /home/
RUN chmod +x /home/sonos_adhan.sh 
RUN chmod +x /home/starter.sh 

WORKDIR /home

RUN git clone https://github.com/jishi/node-sonos-http-api.git
COPY azan.mp3 /home/node-sonos-http-api/static/clips/

WORKDIR /home/node-sonos-http-api
RUN npm install --production

WORKDIR /home

ENTRYPOINT ["/home/starter.sh"]
