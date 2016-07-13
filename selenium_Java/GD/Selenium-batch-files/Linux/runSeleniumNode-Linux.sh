#!/bin/bash

export DISPLAY=:0
java -Dwebdriver.chrome.driver="/root/Selenium/chromedriver" \
 -jar selenium-server-standalone-2.42.2.jar \
 -role node -hub http://192.168.128.76:4444/grid/register \
 -browser "browserName=firefox,platform=LINUX,maxInstances=2" \
 -browser "browserName=chrome,platform=LINUX,maxInstances=2"