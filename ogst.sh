#!/bin/bash
# Advanced PlugIn for OGST Display
# This avoids the everlasting sleep loop from runcommand
# ... and the ORA solution is at least also not so "very" reliable
#
# Is this reliable??? This gots also some caveeats but it is better prepared
# for new emulators and easier to maintain - we do not need to mess around with
# runcommand script
#
# How to use:
# edit runcommand-onstart.sh and add line $HOME/ogst/ogst.sh ogst_show_system $1 $2
# edit runcommand-onend.sh and add line $HOME/ogst/ogst.sh ogst_show_es es.png
#
# by cyperghost

function process_pitch() {
    local cpids="$(pgrep -P $1)"
        for cpid in $cpids;
            do
                pidarray+=($cpid)
                process_pitch $cpid
            done
}


function ogst_off() {
    if lsmod | grep -q 'fbtft_device'; then
        sudo rmmod fbtft_device &> /dev/null
    fi
}

function ogst_init() {
    if ! lsmod | grep -q 'fbtft_device'; then
        sudo modprobe fbtft_device name=hktft9340 busnum=1 rotate=270 &> /dev/null
    fi
}

function ogst_system() {

    local ENGINE=$2
    local PORT=$1

    # Usecase if PORT and SYSTEM are same then it's very likely for a port
    # This works good for openfodder, cdogs, prince of persia

    [[ $ENGINE == $PORT ]] && ENGINE=generic-port

        case $ENGINE in
            sdlpop|solarus|alephone|generic-port)
               ogst_off

               until [[ -z $(pgrep -f runcommand-onstart.sh) ]]; do
                   sleep 1
               done

               old_val=100
               until [[ ${#pidarray} -eq $old_val ]]; do
                   sleep 2.5
                   old_val=${#pidarray}
                   unset pidarray
                   process_pitch "$(pgrep -f -n runcommand.sh)"
               done

               ogst_init
            ;;
        esac

}


function ogst_show_system() {
    local SYSTEM=$1
    if [[ -e "/home/pigaming/ogst/system-$SYSTEM.png" ]]; then
        mplayer -quiet -nolirc -nosound -vo fbdev2:/dev/fb1 -vf scale=320:240 "/home/pigaming/ogst/system-$SYSTEM.png" &> /dev/null
            else
        mplayer -quiet -nolirc -nosound -vo fbdev2:/dev/fb1 -vf scale=320:240 "/home/pigaming/ogst/ora.png" &> /dev/null
    fi
}

function ogst_show_es() {
    local SYSTEM=$1
    if lsmod | grep -q 'fbtft_device'; then
        [[ -z $SYSTEM ]] && SYSTEM="ora.png"
        mplayer -quiet -nolirc -nosound -vo fbdev2:/dev/fb1 -vf scale=320:240 "/home/pigaming/ogst/$SYSTEM" &> /dev/null
    fi
}


## INIT

#EMULATOR=$3
#SYSTEM=$2
#CASE=$1

case ${1,,} in

    ogst_show_es)
        ogst_show_es $2
    ;;

    ogst_show_system)
        ogst_system $2 $3
        ogst_show_system $2
    ;;

    ogst_off) ogst_off ;;

    ogst_init) ogst_init ;;

esac
