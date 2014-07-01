#!/bin/bash
#
# Toggle touchpad on and off
#
# Author: Heath Thompson
# Email:  Heath.Thompson@gmail.com
#
# For startup wait for desktop to load first.

#while true
#do
#	if ps -A | grep gnome-panel > /dev/null; 
#	then
#		echo 'X loaded'
#		break; 
#	else
#		echo 'X not loaded, waiting...'
#		sleep 5
#	fi
#done

#
# Check to see if appletouch is running
# if lsmod | grep appletouch > /dev/null; 
# then
# 	echo " * Appletouch enabled"; 
# else
# 	echo " * Appletouch either not working or not installed"
# 	killall mouseSwitcher
# fi

while true
do
	# 'xinput list' will list all input devices x detects
	# I could reference my usb mouse by ID but I'm afraid that if I plug
	# another device in before my mouse, it might not have the same ID each
	# time.  So using the device name makes it relatively fail-safe.
	
    #if xinput list 'Microsoft Microsoft? 2.4GHz Transceiver v5.0';
    if xinput list '2.4GHz 2way RF Receiver';
	then
		# Found my usb wireless mouse
		# Disable everything on the Touchpad and turn it off
		synclient TouchpadOff=1 MaxTapTime=0 ClickFinger1=0 ClickFinger2=0 ClickFinger3=0; 
		# Ends all syndaemon capturing which may have been used to monitor the touchpad/keyboard activity
		killall syndaemon
	else
		# My usb wireless mouse isn't present we need the touchpad
		# Reenable Touchpad and configure pad-clicks
		# RTCornerButton is the Right Top Corner on the touchpad
		# 	The value 3 maps it as the right click button
		# RBCornerButton is the Right Bottom Corner on the touchpad
		#	The value 2 maps it as the middle click button
		synclient TouchpadOff=0 MaxTapTime=150 ClickFinger1=1 ClickFinger2=2 ClickFinger3=3 RTCornerButton=3 RBCornerButton=2;
		# Forces break of touchpad functions while typing if the touchpad is enabled.
		# Adds a 3 second interval following keyboard use which helps to prevent the
		# mouse from jumping while typing & resting hands on restpad or the touchpad
		#syndaemon -i 3 -d;
        if ! ps -A | grep syndaemon; then syndaemon -i 3 -d; fi;
	fi
	
	# wait 2 seconds and poll the mouse state again
	sleep 2
done

sleep 15
