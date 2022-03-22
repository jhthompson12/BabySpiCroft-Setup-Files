#!/bin/bash
gst-launch-1.0 -v rpicamsrc vflip=true hflip=true \
	       name=src preview=0 fullscreen=0 bitrate=10000000 \
	       annotation-mode=time annotation-text-size=20 \
	       ! video/x-h264,width=960,height=540,framerate=24/1 \
	       ! h264parse \
	       ! rtph264pay config-interval=1 pt=96 \
	       ! queue max-size-bytes=0 max-size-buffers=0 \
	       ! udpsink host=localhost port=5001 \
	       alsasrc device=plug:dsnooped provide-clock=false \
	       ! audio/x-raw,rate=16000 \
               ! audiorate \
	       ! audioconvert \
	       ! audioresample \
	       ! opusenc \
	       ! rtpopuspay \
	       ! queue max-size-bytes=0 max-size-buffers=0 \
	       ! udpsink host=localhost port=5002
