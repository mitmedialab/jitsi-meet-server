#!/usr/bin/env bash

# Simple script to ensure a current build of Jitsi Meet.

cd /var/www/html/jitsi-meet
npm install && make compile && make uglify && make deploy && make clean
