#!/bin/bash

{
  echo "Starting nginx"
  nginx "$@" && exit 1
} &

nginx_pid=$!

watches=${WATCH_PATHS:-"/etc/nginx/nginx.conf"}

echo "Setting up watches for ${watches[@]}"

{
  echo $nginx_pid
  inotifywait -e modify,move,create,delete --timefmt '%d/%m/%y %H:%M' -m --format '%T' \
  ${watches[@]} | while read date time; do

    echo "At ${time} on ${date}, config file update detected"
    nginx -t
    if [ $? -ne 0 ]; then
      echo "ERROR: New configuration is invalid!!"
    else
      echo "New configuration is valid, reloading nginx"
      nginx -s reload
    fi
  done
  echo "inotifywait failed, killing nginx"

  kill -TERM $nginx_pid
} &

wait $nginx_pid || exit 1
