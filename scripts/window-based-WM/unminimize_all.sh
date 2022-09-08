#!/bin/bash
let i=0
for n in $(wmctrl -l | awk -v name=$1 '$0 ~ name{print $2, $1}');
do  
    if [ "$n" != "-1" -a "$i" -eq "0" ]
    then
        wmctrl -ia $n
        sleep 0.02
    else if [ "$i" -eq "0" ]
        then
            let i=1
        else
            let i=0
        fi
    fi
done
