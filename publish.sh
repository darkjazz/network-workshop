#!/bin/bash
rm rewire-workshop.zip
sudo rm -r rewire-workshop
mkdir -p rewire-workshop
cp -r network-workshop-extensions rewire-workshop/
cp d1-s1-basics.scd rewire-workshop/1-basics-sequencing.scd
cp d1-s2-networking.scd rewire-workshop/2-synthesis-network.scd
cp d2-s2-listen.scd rewire-workshop/3-trigger-listening.scd
cp send-me-code.scd rewire-workshop/
cd rewire-workshop/
zip -r -X ../rewire-workshop.zip ./*
cd ..
sudo mkdir -p /Library/WebServer/Documents/rewire
sudo cp rewire-workshop.zip /Library/WebServer/Documents/rewire/
