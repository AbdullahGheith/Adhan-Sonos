FROM node:erbium-alpine3.14

RUN apk update
RUN apk upgrade
RUN apk add --update bash && rm -rf /var/cache/apk/*
RUN apk add tzdata
RUN apk add nano 
RUN apk add git
RUN apk add jq
RUN apk add curl
RUN apk add dateutils
RUN apk add python3
RUN apk add py3-pip
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

RUN touch /etc/crontabs/azancron
RUN chmod 0644 /etc/crontabs/azancron
RUN crontab /etc/crontabs/azancron

WORKDIR /home

ENTRYPOINT ["/home/starter.sh"]
