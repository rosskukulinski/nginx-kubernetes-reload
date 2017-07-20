#!/bin/bash


log() {
  date_time="$(date +%Y-%m-%d\ %H:%M:%S)"
  if [ -z $2 ]; then
    echo "${date_time} nginx: $1"
  else
    (>&2 echo "${date_time} nginx: ERROR: $1")
  fi
}


{
  log "starting"
  nginx -g 'daemon off;' "$@" && exit 1
} &

nginx_pid=$!

watches=${NGINX_WATCH_PATHS:-"/etc/nginx/nginx.conf"}
config_file=${NGINX_CONFIG_FILE:-"/etc/nginx/nginx.conf"}

log "setting up watches for ${watches[@]}"

{
  log "pid $nginx_pid"
  inotifywait -r -q -e modify,move,create,delete --format '%w %e %T' -m --timefmt '%H%M%S'  \
  ${watches[@]} | while read file event tm; do
    current=$(date +'%H%M%S')
    delta=`expr $current - $tm`
    log "at ${tm} config file ${file} update detected (${event})"
    if [ $delta -lt 2 -a $delta -gt -2 ] ; then
      sleep 2  # sleep 1 set to let file operations end
      log "will test config  $config_file"
      nginx -t -c $config_file
      if [ $? -ne 0 ]; then
        log "new configuration is invalid!!" 1
      else
        log "new configuration is valid, reloading"
        nginx -s reload
      fi
    fi
  done
  log "inotifywait failed, killing nginx" 1

  kill -TERM $nginx_pid
} &

wait $nginx_pid || exit 1
