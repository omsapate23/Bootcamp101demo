#!/usr/bin/env bash
set -euo pipefail

echo "Restarting Bootcamp Desktop services..."

if supervisorctl -c /etc/bootcamp-supervisord.conf pid >/dev/null 2>&1; then
    supervisorctl -c /etc/bootcamp-supervisord.conf restart all
else
    bash /usr/local/bin/bootcamp-start
fi

# Run readiness check
for attempt in $(seq 1 30); do
    if DISPLAY=:1 xdpyinfo >/dev/null 2>&1 \
       && pgrep -u "$(id -u)" -x xfce4-session >/dev/null \
       && curl -fsS http://127.0.0.1:6080/vnc.html >/dev/null; then
        echo "Bootcamp Desktop restarted successfully. Port: 6080, VNC password: 101"
        exit 0
    fi
    sleep 1
done

echo "Desktop restart did not complete. Diagnostic status:"
supervisorctl -c /etc/bootcamp-supervisord.conf status || true
exit 1
