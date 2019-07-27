#!/bin/sh
curl -L https://github.com/yuceltoluyag/archyukle/archive/master.zip --output scripts.zip
pacman -Sy --noconfirm unzip
unzip scripts.zip
cd archyukle
chmod +x *.sh
./install.sh
