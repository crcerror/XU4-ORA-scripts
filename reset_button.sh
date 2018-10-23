#!/bin/bash
# Make right button work
#
# if emulator is detected is kills the process
# if no emulator is running ES will be restarted (properly!)
#
# by cyperghost

getcpid() {
local cpid
local cpids="$(pgrep -P $1)"
    for cpid in $cpids;
    do
        pidarray+=($cpid)
        getcpid $cpid
    done
}

smart_wait() {
    local PID=$1
    while [[ -e /proc/$PID ]]
    do
        sleep 0.25
    done
}

kill_pid() {
     for ((z=${#pidarray[*]}-1; z>-1; z--))
     do
          [ -e /proc/${pidarray[z]} ] && kill ${pidarray[z]} && smart_wait ${pidarray[z]}
     done
}

[ -z $1 ] && rightswitch=24 || rightswitch=$1

echo $rightswitch > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio$rightswitch/direction

while true; do
    sleep 1
    status=$(cat /sys/class/gpio/gpio$rightswitch/value)
    if [[ $status == "0" ]]; then
         rc_pid="$(pgrep -f -n runcommand.sh)"
         es_pid="$(pidof emulationstation)"
         [[ -n $rc_pid && -n $es_pid ]] && getcpid $rc_pid && kill_pid 
         [[ -z $rc_pid && -n $es_pid ]] && touch /tmp/es-restart && chown pigaming:pigaming /tmp/es-restart && kill $es_pid 
    fi
done

echo $rightswitch > /sys/class/gpio/unexport
