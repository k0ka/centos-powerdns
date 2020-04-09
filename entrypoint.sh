#!/bin/sh
#
# From https://github.com/psi-4ward/docker-powerdns
#
set -e

# --help, --version
[ "$1" = "--help" ] || [ "$1" = "--version" ] && exec pdns_server $1

# treat everything except -- as exec cmd
[ "${1:0:2}" != "--" ] && exec "$@"

PDNS_MYSQL='';
if $MYSQL_AUTOCONF ; then
  if [ -n "$MYSQL_HOST" ]; then
	PDNS_MYSQL="$PDNS_MYSQL --gmysql-host=$MYSQL_HOST"	
  fi 

  if [ -z "$MYSQL_PORT" ]; then
    MYSQL_PORT=3306
  else 
	PDNS_MYSQL="$PDNS_MYSQL --gmysql-port=$MYSQL_PORT"
  fi

  if [ -n "$MYSQL_USER" ]; then
	PDNS_MYSQL="$PDNS_MYSQL --gmysql-user=$MYSQL_USER"
  fi 

  if [ -n "$MYSQL_PASS" ]; then
	PDNS_MYSQL="$PDNS_MYSQL --gmysql-password=$MYSQL_PASS"
  fi 

  if [ -n "$MYSQL_DB" ]; then
	PDNS_MYSQL="$PDNS_MYSQL --gmysql-dbname=$MYSQL_DB"
  fi 

  if [ -z "$MYSQL_DNSSEC" ]; then
    MYSQL_DNSSEC='no'
  else 
    PDNS_MYSQL="$PDNS_MYSQL --gmysql-dnssec='$MYSQL_DNSSEC'"
  fi

  MYSQLCMD="mysql --host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASS} --port=${MYSQL_PORT} -r -N "

  # wait for Database come ready
  isDBup () {
    echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
    echo $?
  }

  RETRY=10
  until [ `isDBup` -eq 0 ] || [ $RETRY -le 0 ] ; do
    echo "Waiting for database to come up"
    sleep 5
    RETRY=$(expr $RETRY - 1)
  done
  if [ $RETRY -le 0 ]; then
    >&2 echo Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT
    exit 1
  fi

  # init database if necessary
  echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;" | $MYSQLCMD 
  MYSQLCMD="$MYSQLCMD $MYSQL_DB"

  if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"$MYSQL_DB\";" | $MYSQLCMD)" -le 1 ]; then
    echo Initializing Database
    cat /etc/pdns/schema.sql | $MYSQLCMD

    # Run custom mysql post-init sql scripts
    if [ -d "/etc/pdns/mysql-postinit" ]; then
      for SQLFILE in $(ls -1 /etc/pdns/mysql-postinit/*.sql | sort) ; do
        echo Source $SQLFILE
        cat $SQLFILE | $MYSQLCMD
      done
    fi
  fi

  unset -v MYSQL_PASS
fi

# Run pdns server
trap "pdns_control quit" SIGHUP SIGINT SIGTERM

pdns_server "$@" ${PDNS_MYSQL} &

wait
