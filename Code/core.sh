#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SCRIPTS="$DIR/scripts"

function usage {
  echo
  echo "Quickly start, stop or restart Apiaro's esential services in detached screens"
  echo
  echo "usage: $0 [-h] (start [-v|-c]|stop|restart)"
  echo "      -h             this help message"
  echo "      start          starts apiaro-service, apiaro-skills, apiaro-voice and apiaro-cli in quiet mode"
  echo "      start -v       starts apiaro-service, apiaro-skills and apiaro-voice"
  echo "      start -c       starts apiaro-service, apiaro-skills and apiaro-cli"
  echo "      stop           stops apiaro-service, apiaro-skills and apiaro-voice"
  echo "      restart        restarts apiaro-service, apiaro-skills and apiaro-voice"
  echo
  echo "screen tips:"
  echo "            run 'screen -list' to see all running screens"
  echo "            run 'screen -r <screen-name>' (e.g. 'screen -r apiaro-service') to reatach a screen"
  echo "            press ctrl + a, ctrl + d to detace the screen again"
  echo "            See the screen man page for more details"
  echo
}

mkdir -p $SCRIPTS/logs

function verify-start {
    if ! screen -list | grep -q "$1";
    then
      echo "$1 failed to start. The log is below:"
      echo
      tail $SCRIPTS/logs/$1.log
    exit 1
    fi
}

function start-mycroft {
  screen -mdS mycroft-$1$2 -c $SCRIPTS/mycroft-$1.screen $DIR/start.sh $1 $2
  sleep 1
  verify-start mycroft-$1$2
  echo "Apiaro $1$2 started"
}

function stop-mycroft {
    if screen -list | grep -q "$1";
    then
      screen -XS mycroft-$1 quit
      echo "Apiaro $1 stopped"
    fi
}

function restart-mycroft {
    if screen -list | grep -q "quiet";
    then
      $0 stop
      sleep 1
      $0 start
    elif screen -list | grep -q "cli" && ! screen -list | grep -q "quiet";
    then
      $0 stop
      sleep 1
      $0 start -c
    elif screen -list | grep -q "voice" && ! screen -list | grep -q "quiet";
    then
      $0 stop
      sleep 1
      $0 start -v
    else
      echo "An error occurred"
    fi
}

set -e

if [[ -z "$1" || "$1" == "-h" ]]
then
  usage
  exit 1
elif [[ "$1" == "start" && -z "$2" ]]
then
  start-mycroft service
  start-mycroft skills
  start-mycroft voice
  start-mycroft cli --quiet
  exit 0
elif [[ "$1" == "start" && "$2" == "-v" ]]
then
  start-mycroft service
  start-mycroft skills
  start-mycroft voice
  exit 0
elif [[ "$1" == "start" && "$2" == "-c" ]]
then
  start-mycroft service
  start-mycroft skills
  start-mycroft cli
  exit 0
elif [[ "$1" == "stop" && -z "$2" ]]
then
  stop-mycroft service
  stop-mycroft skills
  stop-mycroft voice
  stop-mycroft cli
  exit 0
elif [[ "$1" == "restart" && -z "$2" ]]
then
  restart-mycroft
  exit 0
else
  usage
  exit 1
fi
