#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.vnc" "$HOME/Desktop" "$HOME/.bootcamp"

# Create the password only on first startup.
# Keep the forwarded port PRIVATE.
if [ ! -s "$HOME/.vnc/passwd" ]; then
    printf '%s\n' '101' | tigervncpasswd -f > "$HOME/.vnc/passwd"
fi
chmod 600 "$HOME/.vnc/passwd"

# Keep XFCE running for the lifetime of the VNC session.
cat > "$HOME/.vnc/bootcamp-xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

exec dbus-run-session -- xfce4-session
EOF

chmod +x "$HOME/.vnc/bootcamp-xstartup"

# Add an easily accessible terminal to the desktop.
cat > "$HOME/Desktop/Terminal.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
EOF

cat > "$HOME/Desktop/Wireshark.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wireshark
Exec=wireshark
Icon=wireshark
Terminal=false
EOF

chmod +x "$HOME/Desktop/"*.desktop

# Link challenge files if the repository contains them.
# Missing challenges do not break desktop startup.
if [ -d "$PWD/challenges" ]; then
    ln -sfn "$PWD/challenges" "$HOME/Desktop/Challenges"
elif [ -d "/workspaces/Bootcamp101demo/challenges" ]; then
    ln -sfn "/workspaces/Bootcamp101demo/challenges" "$HOME/Desktop/Challenges"
else
    for dir in /workspaces/*/challenges; do
        if [ -d "$dir" ]; then
            ln -sfn "$dir" "$HOME/Desktop/Challenges"
            break
        fi
    done
fi

# Clean up stale supervisor locks/sockets if supervisor is not actually running
if [ -f "$HOME/.bootcamp/supervisor.pid" ]; then
    SUPERVISOR_PID=$(cat "$HOME/.bootcamp/supervisor.pid" 2>/dev/null || echo "")
    if [ -n "$SUPERVISOR_PID" ] && ! kill -0 "$SUPERVISOR_PID" 2>/dev/null; then
        rm -f "$HOME/.bootcamp/supervisor.pid" "$HOME/.bootcamp/supervisor.sock"
    fi
fi

# Clean stale VNC locks if Xvnc is not running
if [ -f /tmp/.X1-lock ] || [ -S /tmp/.X11-unix/X1 ]; then
    if ! pgrep -f "Xvnc :1|Xtigervnc.*:1" >/dev/null 2>&1; then
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
    fi
fi

# Avoid starting a second Supervisor instance.
if ! supervisorctl -c /etc/bootcamp-supervisord.conf \
     pid >/dev/null 2>&1; then
    tigervncserver -list -cleanstale 2>/dev/null || true
    supervisord -c /etc/bootcamp-supervisord.conf
fi

# Wait until both the desktop and browser gateway respond.
for attempt in $(seq 1 30); do
    if DISPLAY=:1 xdpyinfo >/dev/null 2>&1 \
       && pgrep -u "$(id -u)" -x xfce4-session >/dev/null \
       && curl -fsS http://127.0.0.1:6080/vnc.html >/dev/null; then
        echo "Desktop ready. Open port 6080. VNC password: 101"
        exit 0
    fi
    sleep 1
done

echo "Desktop startup did not finish. Diagnostic information:"
supervisorctl -c /etc/bootcamp-supervisord.conf status || true
tail -n 40 "$HOME/.bootcamp/vnc.log" \
           "$HOME/.bootcamp/novnc.log" \
           "$HOME/.bootcamp/supervisor.log" 2>/dev/null || true
exit 1