#!/bin/bash

monit stop iptv-sim
monit stop hls-sim
monit stop dvb-sim
monit summary
