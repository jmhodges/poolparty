#!/bin/sh

export SINATRA_ENV=production
case $1 in
	start)
	echo $$ > /apps/poolparty-test/server.4567.pid;
  cd /usr/local/src/poolparty && git pull origin master && rake manifest gem install
	exec 2>&1 /usr/bin/ruby -C/apps/poolparty-test /apps/poolparty-test/server.rb -p 4567 -e production
	;;
  stop)
  kill `cat /apps/poolparty-test/server.4567.pid`
  ;;
  *)
  echo "Usage: sinatra (start|stop)"
  ;;
esac
