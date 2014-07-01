#!/bin/sh
# first param is either -d or -e and secondn is package name of app
adb $1 shell kill $(adb $1 shell ps | grep $2 | awk '{ print $2 }')
