FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Suppress interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Wireshark, tshark, and terminal tools
RUN apt-get update && apt-get install -y \
    wireshark \
    tshark \
    xfce4-terminal \
    dbus-x11

# Automatically bypass the Wireshark root restriction prompt
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections \
    && dpkg-reconfigure -f noninteractive wireshark-common \
    && usermod -aG wireshark vscode