#!/bin/bash
# Advanced PlugIn for OGST Display (Artificial Intelligence)
# This avoids the everlasting sleep loop from runcommand
# ... and the ORA solution is at least also not so "very" reliable
#
# Is this reliable??? This gots also some caveeats but it is better prepared
# for new emulators and easier to maintain - we do not need to mess around with
# runcommand script and and case of failure we can just edit config file and change sleeptime
#
# How it works? It registers all binaries to a cfg located next to script
# usually it's $HOME/ogst/ogst_ai.cfg. There the binary of emulator
# system and emulator is listed. The number is the sleep timer after
# such seconds the display is activated!
#
# How to use:
# edit runcommand-onstart.sh and add line $HOME/ogst/ogst_ai.sh ogst_show_system $1 $2
# edit runcommand-onend.sh and add line $HOME/ogst/ogst_ai.sh ogst_show_es es.png
#
# by cyperghost

function get_ogst_param() {
    touch "$CONFIGFILE"
    while read -r f1 f2 f3 f4; do
        if [[ $EMULATOR == $f2 && $SYSTEM == $f3 ]]; then
            BINARY="$f1"
            SYSTEM="$f3"
            EMULATOR="$f2"
            SLEEP="$f4"
        fi
    done < <(tr -d '\r' < "$CONFIGFILE")
}

function get_pid2name() {
    local cpid=$1
    echo "$(ps -p $cpid -o comm=)"
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

function system_ai() {

    # Usecase if PORT and SYSTEM are same then it's very likely for a port
    # This works good for openfodder, cdogs, prince of persia

               until [[ -z $(pgrep -f runcommand-onstart.sh) ]]; do
                   sleep 0.5
               done

               local c_pid="$(pgrep -f -n runcommand.sh)"
               local c2pid=$c_pid
               local old_pid

               SLEEP=0
               until [[ $c_pid == $old_pid && $SLEEP -gt 2 ]]; do
                   ((SLEEP++))
                   sleep 1
                   c_pid=$(pgrep -P $c_pid) && old_pid=$c_pid || c_pid=$c2pid
               done
               echo "$c_pid $SLEEP"
}


function system_data() {
    local EMULATOR=$1
    local SLEEP=$2

    # Usecase if PORT and SYSTEM are same then it's very likely for a port
    # This works good for openfodder, cdogs, prince of persia

              if [[ $BINARY == retroarch ]]; then
                  ogst_init
                  return
              fi

               ogst_off
              
               until [[ -z $(pgrep -f runcommand-onstart.sh) ]]; do
                   sleep 0.5
               done

               until [[ -n $(pidof $BINARY) ]]; do
                   sleep $SLEEP
               done

               ogst_init
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
BINARY=
EMULATOR=$3
SYSTEM=$2
CASE=$1

readonly SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
readonly CONFIGFILE="${SCRIPTDIR}/ogst_ai.cfg"
[[ $EMULATOR == lr* ]] && BINARY="retroarch"
case ${CASE,,} in
    ogst_show_es)
        ogst_show_es $SYSTEM
    ;;
    ogst_show_system)
        get_ogst_param
        # DATA found?
        if [[ -z $SLEEP ]]; then
            ogst_off
            cpid="$(system_ai)"
            SLEEP=$((${cpid#* }+2))
            PID="${cpid% *}"
            BINARY="$(get_pid2name $PID)"
            echo "$BINARY $EMULATOR $SYSTEM $SLEEP" >> "$CONFIGFILE"
        else
            system_data $EMULATOR $SLEEP
            ogst_show_system $SYSTEM
        fi
    ;;
    ogst_off) ogst_off ;;
    ogst_init) ogst_init ;;
esac
