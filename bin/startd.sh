#! /bin/sh

### BEGIN INIT INFO
# Provides:          ewok
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the ewok application server
# Description:       starts ewok using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/erl
NAME=ewok
DESC=ewok

# test -x $DAEMON || exit 0

# Include ewok defaults if available
if [ -f /etc/ewok.conf ] ; then
        . /etc/ewok.conf
fi

set -e

#. /lib/lsb/init-functions

case "$1" in
  start)
        echo -n "Starting $DESC: "
        start-stop-daemon --start --quiet --pidfile /var/run/$NAME.pid \
                --exec $DAEMON -- $DAEMON_OPTS || true
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --quiet --pidfile /var/run/$NAME.pid \
                --exec $DAEMON || true
        echo "$NAME."
        ;;
  restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --quiet --pidfile \
                /var/run/$NAME.pid --exec $DAEMON || true
        sleep 1
        start-stop-daemon --start --quiet --pidfile \
                /var/run/$NAME.pid --exec $DAEMON -- $DAEMON_OPTS || true
        echo "$NAME."
        ;;
  reload)
      echo -n "Reloading $DESC configuration: "
      start-stop-daemon --stop --signal HUP --quiet --pidfile /var/run/$NAME.pid \
          --exec $DAEMON || true
      echo "$NAME."
      ;;
  status)
      status_of_proc -p /var/run/$NAME.pid "$DAEMON" ewok && exit 0 || exit $?
      ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|reload|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0
