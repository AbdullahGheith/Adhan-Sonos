#!/bin/bash

mkdir /home/go-chromecast
archtype=$(uname -m)
if  [[ $archtype =~ "x86" ]]; then
        downloadurl=https://github.com/vishen/go-chromecast/releases/download/v0.2.10/go-chromecast_0.2.10_linux_386.tar.gz
elif [[ $archtype =~ "armv7" ]]; then
        downloadurl=https://github.com/vishen/go-chromecast/releases/download/v0.2.10/go-chromecast_0.2.10_linux_armv7.tar.gz
elif [[ $archtype =~ "armv6" ]]; then
        downloadurl=https://github.com/vishen/go-chromecast/releases/download/v0.2.10/go-chromecast_0.2.10_linux_armv6.tar.gz
fi

if test -n "${downloadurl-}"; then
        wget -P /home/go-chromecast/ $downloadurl
        mv /home/go-chromecast/go-chromec* /home/go-chromecast/go-chromecast.tar.gz
        tar -xzf /home/go-chromecast/go-chromecast.tar.gz -C /home/go-chromecast
        install /home/go-chromecast/./go-chromecast /usr/bin/
else
        printf "Couldnt find go-chromecast for your arch. Implement arch in initchromecast.sh: $(uname -m)"
        echo -e "\n"
fi