#!/bin/bash
for n in $(wmctrl -l | awk -v name=$1 '$0 ~ name{print $4}');
do
    xdotool getactivewindow windowminimize
    sleep 0.08
done
