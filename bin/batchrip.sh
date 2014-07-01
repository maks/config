#!/bin/bash

# first arg is name of rip files

for i in {3..6}
do
   handbrake -e ffmpeg -E vorbis -t $i -S 200 -w 720 -l 576 -i /dev/scd1 -o $1$i.avi
done