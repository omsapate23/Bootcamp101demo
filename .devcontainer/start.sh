#!/usr/bin/env bash
set -euo pipefail

# Establish runtime directories
mkdir -p "$HOME/.vnc" "$HOME/Desktop" "$HOME/.bootcamp" "$HOME/.local/bin"

# Determine workspace directory
WORKSPACE_DIR="/home/vscode"
if [ -d "/workspaces/Bootcamp101demo" ]; then
    WORKSPACE_DIR="/workspaces/Bootcamp101demo"
else
    for dir in /workspaces/*; do
        if [ -d "$dir" ] && [ "$dir" != "/workspaces" ]; then
            WORKSPACE_DIR="$dir"
            break
        fi
    done
fi

# Create the password only on first startup (default: 101)
if [ ! -s "$HOME/.vnc/passwd" ]; then
    printf '%s\n' '101' | tigervncpasswd -f > "$HOME/.vnc/passwd"
fi
chmod 600 "$HOME/.vnc/passwd"

# Keep XFCE running inside its own D-Bus session for the lifetime of the VNC session
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

# Add desktop launchers if not present or preserve user edits
cat > "$HOME/Desktop/Terminal.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Open XFCE Terminal in workspace
Exec=xfce4-terminal --working-directory=${WORKSPACE_DIR}
Icon=org.xfce.terminal
Terminal=false
StartupNotify=true
EOF

cat > "$HOME/Desktop/FileManager.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Comment=Open Thunar File Manager in workspace
Exec=thunar ${WORKSPACE_DIR}
Icon=org.xfce.thunar
Terminal=false
StartupNotify=true
EOF

cat > "$HOME/Desktop/Wireshark.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wireshark
Comment=Open Wireshark Network Analyzer
Exec=wireshark %f
Icon=wireshark
Terminal=false
StartupNotify=true
EOF

# Discover challenge directory if present in repository
CHALLENGES_DIR=""
if [ -d "$PWD/challenges" ]; then
    CHALLENGES_DIR="$PWD/challenges"
elif [ -d "$WORKSPACE_DIR/challenges" ]; then
    CHALLENGES_DIR="$WORKSPACE_DIR/challenges"
else
    for dir in /workspaces/*/challenges; do
        if [ -d "$dir" ]; then
            CHALLENGES_DIR="$dir"
            break
        fi
    done
fi

if [ -n "$CHALLENGES_DIR" ] && [ -d "$CHALLENGES_DIR" ]; then
    ln -sfn "$CHALLENGES_DIR" "$HOME/Desktop/Day 1 Challenges"
    cat > "$HOME/Desktop/Challenges.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Day 1 Challenges
Comment=Open Bootcamp Challenges Folder
Exec=thunar "${CHALLENGES_DIR}"
Icon=folder
Terminal=false
StartupNotify=true
EOF
fi

# Set executable permissions so XFCE trusts the desktop launchers
chmod +x "$HOME/Desktop/"*.desktop 2>/dev/null || true

# Clean up stale supervisor locks/sockets if supervisor is not actually running
if [ -f "$HOME/.bootcamp/supervisor.pid" ]; then
    SUPERVISOR_PID=$(cat "$HOME/.bootcamp/supervisor.pid" 2>/dev/null || echo "")
    if [ -n "$SUPERVISOR_PID" ] && ! kill -0 "$SUPERVISOR_PID" 2>/dev/null; then
        rm -f "$HOME/.bootcamp/supervisor.pid" "$HOME/.bootcamp/supervisor.sock"
    fi
fi

# Clean stale VNC locks safely for display :1 only if Xtigervnc is not running
if [ -f /tmp/.X1-lock ] || [ -S /tmp/.X11-unix/X1 ]; then
    if ! pgrep -f "Xvnc :1|Xtigervnc.*:1" >/dev/null 2>&1; then
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
    fi
fi

# Avoid starting a second Supervisor instance if already active
if ! supervisorctl -c /etc/bootcamp-supervisord.conf pid >/dev/null 2>&1; then
    tigervncserver -list -cleanstale 2>/dev/null || true
    supervisord -c /etc/bootcamp-supervisord.conf
fi

# Bounded readiness check (up to 30 seconds)
for attempt in $(seq 1 30); do
    if DISPLAY=:1 xdpyinfo >/dev/null 2>&1 \
       && pgrep -u "$(id -u)" -x xfce4-session >/dev/null \
       && curl -fsS http://127.0.0.1:6080/vnc.html >/dev/null; then
        echo "Bootcamp Desktop is ready. Open port 6080. VNC password: 101"
        exit 0
    fi
    sleep 1
done

echo "Desktop startup did not finish within timeout. Diagnostic information:"
supervisorctl -c /etc/bootcamp-supervisord.conf status || true
tail -n 40 "$HOME/.bootcamp/vnc.log" \
           "$HOME/.bootcamp/novnc.log" \
           "$HOME/.bootcamp/supervisor.log" 2>/dev/null || true
exit 1