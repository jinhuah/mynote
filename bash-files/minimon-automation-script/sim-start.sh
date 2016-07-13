#!/bin/bash

monit summary
monit start iptv-sim
monit start hls-sim
monit start dvb-sim
sleep 5
monit summary
