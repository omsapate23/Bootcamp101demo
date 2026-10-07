# Cybersecurity Bootcamp 101 - Browser Desktop Environment

Welcome to the Cybersecurity Bootcamp! This repository provides an automated, browser-accessible Ubuntu Linux desktop environment powered by GitHub Codespaces.

---

## 1. Installed Tools & Capabilities

This container image provides a focused, practical Linux teaching workstation:

### Core Linux Utilities
* **Shell & Discovery**: `bash`, `bash-completion`, `coreutils` (`ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`, `chmod`), `findutils` (`find`), `grep`, `sed`, `gawk`.
* **System & Process Tools**: `procps` (`ps`, `top`, `pgrep`, `pkill`), `psmisc` (`killall`), `util-linux`, `sudo`.
* **Inspection & Documentation**: `file`, `less`, `tree`, `man-db` (`man`).
* **Text Editors**: `nano`, `vim`, and GUI `mousepad`.
* **Networking & Transfer**: `git`, `curl`, `wget`, `ca-certificates`.

### Archives & Compression
* **Tools**: `tar`, `gzip`, `bzip2`, `xz-utils`, `zip`, `unzip`, `7z` (via `7zip`).
* **GUI Archive Manager**: `xarchiver`.

### Python Ecosystem
* **Python 3**: `python3`, `python` (via `python-is-python3`), `python3-pip`, `python3-venv`, and `pipx`.
* **Protected System Python**: Ubuntu 24.04 enforces externally managed Python environments (PEP 668). System packages cannot be overwritten with `sudo pip`. Use `python3 -m venv` or `pipx`.

### Networking & Packet Analysis
* **Network Diagnostics**: `iproute2` (`ip`, `ss`), `iputils-ping` (`ping`), `dnsutils` (`dig`, `nslookup`), `netcat-openbsd` (`nc`), `openssh-client` (`ssh`), `traceroute`, `tcpdump`.
* **Protocol Analysis**: `wireshark` (GUI) and `tshark` (CLI), pre-configured for non-root capture inspection.

### Cryptography & File Forensics
* **Cryptography & Hex**: `openssl`, `binutils` (`strings`, `objdump`, `nm`), `xxd`, `sha256sum`, `base64`.
* **File Metadata & Carving**: `binwalk` (firmware/archive analysis), `exiftool` (metadata extraction via `libimage-exiftool-perl`).
* *Note on Extraction*: Standard formats (zip, tar, gzip, 7z) are supported out of the box. Proprietary firmware decompression routines that require specialized external proprietary kernels are not included.

### Desktop Environment
* **Window Manager**: Lightweight XFCE4 session running with its own D-Bus session.
* **File Manager**: Thunar (`thunar`).
* **Terminal**: XFCE Terminal (`xfce4-terminal`), configured to start directly in the repository workspace.
* **Fonts**: `fonts-dejavu-core`, `fonts-liberation`.
* **VNC Server**: TigerVNC bound strictly to `127.0.0.1:5901` (localhost only).
* **Web Gateway**: noVNC + Websockify on port `6080` (Codespaces visibility set to `private`).
* **Default VNC Password**: `101`

---

## 2. Student Guide: Getting Started

### Launching Your Codespace
1. Open this repository on GitHub.
2. Click the green **Code** button &rarr; switch to the **Codespaces** tab.
3. Click **Create codespace on main**.
4. GitHub Codespaces will pull the pre-built container image. First startup typically takes 15–30 seconds.

### Opening the Desktop GUI
* Once the container starts, port `6080` is forwarded automatically. Codespaces will open the desktop in a new browser tab or display a notification to open it.
* If a popup blocker intercepts it:
  1. Click the **Ports** tab in the bottom panel of VS Code.
  2. Locate port `6080 (Bootcamp Desktop)`.
  3. Click the **Open in Browser** globe icon.
* If prompted for a password, enter: `101`

### Using Desktop Launchers & Challenges
* **Terminal**: Double-click the **Terminal** icon on the desktop to open a bash shell in `/workspaces/Bootcamp101demo`.
* **File Manager**: Double-click **File Manager** to browse workspace and system files.
* **Wireshark**: Double-click **Wireshark** to launch the GUI analyzer.
* **Day 1 Challenges**: If the repository includes challenge files, a **Day 1 Challenges** folder and launcher will appear on your desktop.

---

## 3. Working with Python

### Creating a Virtual Environment
To install Python packages for a specific project or challenge without conflicting with system packages:
```bash
# Create a virtual environment named .venv
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Install your dependencies inside the isolated environment
pip install requests pycryptodome

# Deactivate when finished
deactivate
```

### Installing Isolated CLI Tools with pipx
To install standalone Python tools:
```bash
pipx install <tool-name>
```
Commands installed via `pipx` are automatically added to your `$PATH` in `~/.local/bin`.

---

## 4. Diagnostics & Service Management

The desktop environment is managed by **Supervisor**.

### Checking Service Status
In the VS Code terminal or XFCE terminal, run:
```bash
bootcamp-status
```
or directly check Supervisor:
```bash
supervisorctl -c /etc/bootcamp-supervisord.conf status
```

### Restarting Desktop Services
If the VNC desktop stops responding:
```bash
bootcamp-restart
```

### Viewing Logs
* **VNC Server Log**: `cat ~/.bootcamp/vnc.log`
* **noVNC Web Gateway Log**: `cat ~/.bootcamp/novnc.log`
* **Supervisor Log**: `cat ~/.bootcamp/supervisor.log`

---

## 5. Session Management & Data Persistence

### Stopping & Resuming Your Codespace
* **After Class**: Close the browser tab. Codespaces automatically suspends idle environments after a default timeout (typically 30 minutes) to conserve monthly quotas.
* **Explicit Stop**: In VS Code, press `Ctrl+Shift+P` (or `Cmd+Shift+P`) and select **Codespaces: Stop Current Codespace**.
* **Resuming**: Visit [github.com/codespaces](https://github.com/codespaces) and click your Codespace to resume where you left off.

### What Survives Stop/Start vs Rebuild
* **Survives Stop / Resume**: All files inside `/workspaces/Bootcamp101demo`, student files created in `/home/vscode`, bash history, and installed virtual environments.
* **Lost on Container Rebuild**: System-wide packages installed via `sudo apt` during a live session (unless added to the Dockerfile) and temporary files in `/tmp`.

---

## 6. Container Limitations & Security Boundaries

This environment runs as a Linux container inside a cloud virtual machine. Please note the following:

1. **Packet Capture & Wireshark**:
   * Wireshark is intended for **offline analysis** of supplied `.pcap` and `.pcapng` capture files.
   * Wireshark inside Codespaces captures virtual container network interfaces (`eth0`, `lo`), and **cannot** sniff your personal laptop's physical Wi-Fi or local network adapters.
2. **Hardware Access**:
   * Physical USB, Bluetooth, GPU pass-through, and raw Wi-Fi adapters from your personal laptop are not connected to the container.
3. **No Systemd as PID 1**:
   * System services are managed by **Supervisor**, not `systemd`. Use `bootcamp-status` and `bootcamp-restart` instead of `systemctl`.
4. **Sudo Boundary**:
   * The `vscode` user has passwordless `sudo` privileges inside the container to install packages or inspect files, but `sudo` does not grant administrative access to the underlying GitHub cloud host.

---

## 7. Instructor Guide: Publishing Updates

### Building & Testing the Image in GitHub Actions
1. Push changes in `.devcontainer/` or `tests/` to the `main` branch, or manually trigger the workflow:
   * Go to **Actions** &rarr; **Build, Verify & Push Desktop Image** &rarr; **Run workflow**.
2. The workflow builds the image, runs the full automated smoke test suite (`tests/smoke_test.sh`), and only pushes to `ghcr.io/omsapate23/bootcamp-desktop` upon 100% test pass.

### Setting Package Visibility to Public (One-time Setup)
1. Go to your GitHub profile &rarr; **Packages** (`https://github.com/omsapate23?tab=packages`).
2. Select **`bootcamp-desktop`** &rarr; **Package settings**.
3. In the **Danger Zone**, click **Change visibility** &rarr; select **Public** and confirm.

### How Existing Students Receive Updates
When a new container image is published:
* **New Codespaces**: Automatically pull the newest image on creation.
* **Existing Codespaces**: Existing students must open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **`Codespaces: Rebuild Container`** to pull the updated image.