FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "wireshark-common wireshark-common/install-setuid boolean true" \
    | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    xauth \
    x11-utils \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    supervisor \
    wireshark \
    tshark \
    mousepad \
    curl \
    && usermod -aG wireshark vscode \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Open the noVNC client automatically when visiting port 6080.
RUN printf '%s\n' \
    '<!doctype html>' \
    '<html><head>' \
    '<meta http-equiv="refresh" content="0;url=vnc.html?autoconnect=true&resize=remote&reconnect=true">' \
    '</head><body>' \
    '<a href="vnc.html?autoconnect=true&resize=remote">Open desktop</a>' \
    '</body></html>' \
    > /usr/share/novnc/index.html

COPY start.sh /usr/local/bin/bootcamp-start
COPY supervisord.conf /etc/bootcamp-supervisord.conf

# Accept files saved with Windows line endings.
RUN sed -i 's/\r$//' \
    /usr/local/bin/bootcamp-start \
    /etc/bootcamp-supervisord.conf \
    && chmod +x /usr/local/bin/bootcamp-start