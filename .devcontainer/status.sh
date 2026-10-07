#!/usr/bin/env bash
set -uo pipefail

echo "=================================================="
echo "          Bootcamp Desktop Service Status         "
echo "=================================================="

echo ""
echo "--- Supervisor Service Status ---"
if supervisorctl -c /etc/bootcamp-supervisord.conf pid >/dev/null 2>&1; then
    supervisorctl -c /etc/bootcamp-supervisord.conf status
else
    echo "Supervisor is NOT running."
fi

echo ""
echo "--- Process Inspection ---"
pgrep -u "$(id -u)" -a || true

echo ""
echo "--- Network & Port Status ---"
if command -v ss >/dev/null 2>&1; then
    ss -tulpn | grep -E ":5901|:6080" || echo "Ports 5901/6080 not listening."
elif command -v netstat >/dev/null 2>&1; then
    netstat -tulpn | grep -E ":5901|:6080" || echo "Ports 5901/6080 not listening."
fi

echo ""
echo "--- Recent VNC Logs (~/.bootcamp/vnc.log) ---"
if [ -f "$HOME/.bootcamp/vnc.log" ]; then
    tail -n 20 "$HOME/.bootcamp/vnc.log"
else
    echo "No VNC log file found."
fi

echo ""
echo "--- Recent noVNC Logs (~/.bootcamp/novnc.log) ---"
if [ -f "$HOME/.bootcamp/novnc.log" ]; then
    tail -n 20 "$HOME/.bootcamp/novnc.log"
else
    echo "No noVNC log file found."
fi

echo ""
echo "--- Recent Supervisor Logs (~/.bootcamp/supervisor.log) ---"
if [ -f "$HOME/.bootcamp/supervisor.log" ]; then
    tail -n 20 "$HOME/.bootcamp/supervisor.log"
else
    echo "No Supervisor log file found."
fi
echo "=================================================="
