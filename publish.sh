#!/bin/bash
mkdir -p rewire-workshop
# mkdir rewire-workshop/
cp -r network-workshop-extensions rewire-workshop/
cp d1-s1-basics.scd rewire-workshop/1-basics-sequencing.scd
cp d1-s2-networking.scd rewire-workshop/2-synthesis-network.scd
cp d2-s2-listen.scd rewire-workshop/3-trigger-listening.scd
cp send-me-code.scd rewire-workshop/
zip rewire-workshop.zip rewire-workshop
