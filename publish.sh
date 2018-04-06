#!/bin/bash
rm network-workshop.zip
sudo rm -r network-workshop
mkdir -p network-workshop
cp -r network-workshop-extensions network-workshop/
cp d1-s1-basics.scd network-workshop/1-basics-sequencing.scd
cp d1-s2-networking.scd network-workshop/2-synthesis-network.scd
cp d2-s2-listen.scd network-workshop/3-trigger-listening.scd
cp send-me-code.scd network-workshop/
cd network-workshop/
zip -r -X ../network-workshop.zip ./*
cd ..
sudo mkdir -p /Library/WebServer/Documents/rewire
sudo cp network-workshop.zip /Library/WebServer/Documents/rewire/
