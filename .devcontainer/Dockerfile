FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Automatically bypass Wireshark root restriction prompt
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" \
    | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    # Core Linux utilities
    bash \
    bash-completion \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    util-linux \
    procps \
    psmisc \
    file \
    less \
    tree \
    man-db \
    manpages \
    nano \
    vim \
    git \
    curl \
    wget \
    ca-certificates \
    sudo \
    # Archives & compression
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zip \
    unzip \
    7zip \
    # Python ecosystem
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    python-is-python3 \
    # Networking utilities
    iproute2 \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    openssh-client \
    traceroute \
    tcpdump \
    wireshark \
    tshark \
    # Basic cryptography & file analysis
    openssl \
    binutils \
    xxd \
    binwalk \
    libimage-exiftool-perl \
    # Desktop environment & X11 / VNC
    xfce4 \
    xfce4-terminal \
    thunar \
    mousepad \
    xarchiver \
    dbus-x11 \
    xauth \
    x11-utils \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    supervisor \
    # Fonts
    fonts-dejavu-core \
    fonts-liberation \
    && usermod -aG wireshark vscode \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure pipx path is globally available for all users
ENV PATH="/home/vscode/.local/bin:${PATH}"
RUN echo 'export PATH="/home/vscode/.local/bin:$PATH"' > /etc/profile.d/pipx.sh

# Open the noVNC client automatically when visiting port 6080.
RUN printf '%s\n' \
    '<!doctype html>' \
    '<html><head>' \
    '<meta http-equiv="refresh" content="0;url=vnc.html?autoconnect=true&resize=remote&reconnect=true">' \
    '</head><body>' \
    '<a href="vnc.html?autoconnect=true&resize=remote">Open desktop</a>' \
    '</body></html>' \
    > /usr/share/novnc/index.html

# Copy helper scripts and supervisor configuration
COPY start.sh /usr/local/bin/bootcamp-start
COPY restart.sh /usr/local/bin/bootcamp-restart
COPY status.sh /usr/local/bin/bootcamp-status
COPY supervisord.conf /etc/bootcamp-supervisord.conf

# Accept files saved with Windows line endings and ensure execution permissions
RUN sed -i 's/\r$//' \
    /usr/local/bin/bootcamp-start \
    /usr/local/bin/bootcamp-restart \
    /usr/local/bin/bootcamp-status \
    /etc/bootcamp-supervisord.conf \
    && chmod +x \
    /usr/local/bin/bootcamp-start \
    /usr/local/bin/bootcamp-restart \
    /usr/local/bin/bootcamp-status