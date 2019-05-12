#!/bin/sh
# Make right button work
# by cyperghost

[ -z $1 ] && rightswitch=24 || rightswitch=$1

echo $rightswitch > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio$rightswitch/direction

until [ "$status" = "0" ]; do
    sleep 0.5
    status=$(cat /sys/class/gpio/gpio$rightswitch/value)
    echo "Status: $status - GPIO: $rightswitch"
done

echo "I am done! Resetting GPIO $rightswitch now!"
echo $rightswitch > /sys/class/gpio/unexport
