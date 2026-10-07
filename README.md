# Cybersecurity Bootcamp 101 - Browser Desktop Environment

Welcome to the Cybersecurity Bootcamp! This repository provides an automated, browser-based Ubuntu XFCE desktop environment powered by GitHub Codespaces.

---

## Architecture Overview

* **Base System**: Ubuntu 24.04 LTS running as non-root user `vscode`.
* **Desktop & Tools**: Lightweight XFCE desktop, XFCE Terminal, Wireshark, TShark, and Mousepad.
* **Process Management**: Supervisor manages the VNC server and WebSocket gateway to ensure automatic startup and crash-recovery.
* **Network & Security**:
  * TigerVNC is strictly bound to `127.0.0.1:5901` (localhost only).
  * noVNC web gateway runs on port `6080` (Codespaces port visibility set to `private`).
  * Default VNC password: `101`
* **Pre-built Container Image**: Stored in GitHub Container Registry (`ghcr.io/omsapate23/bootcamp-desktop:latest`) so students get instant startup without long build times.

---

## Instructor Guide: Publishing the Image & Setting Permissions

### Step 1: Run the GitHub Actions Build Workflow
1. Push your changes to the `main` branch (which triggers `.github/workflows/build-desktop-image.yml` automatically), OR:
2. Go to the **Actions** tab in your GitHub repository.
3. Select **Build and Publish Bootcamp Desktop Image** from the left sidebar.
4. Click **Run workflow** &rarr; Select `main` &rarr; Click **Run workflow**.

### Step 2: Make the GHCR Package Public (One-time Setup)
For 60 students to download the pre-built container image without authentication errors, the package must be set to **Public**:
1. Go to your GitHub profile or repository page.
2. Click on **Packages** (or navigate to `https://github.com/omsapate23?tab=packages`).
3. Click on the package named **`bootcamp-desktop`**.
4. On the right side, click **Package settings**.
5. Scroll down to the **Danger Zone** section and click **Change visibility**.
6. Select **Public**, type the confirmation text, and confirm.

---

## Student Guide: Accessing the Bootcamp Environment

### 1. Launching Your Codespace
1. Open this repository on GitHub in your browser.
2. Click the green **Code** button &rarr; select the **Codespaces** tab.
3. Click **Create codespace on main**.
4. GitHub Codespaces will pull the pre-built image and initialize your environment in VS Code in the browser.

### 2. Opening the Desktop GUI
* Once the container starts, port `6080` is forwarded automatically. A notification will appear asking to **Open in Browser** (or a new browser tab will open automatically).
* If your browser blocks popups, navigate to the **Ports** tab at the bottom of VS Code, find port `6080 (Bootcamp Desktop)`, and click the **Open in Browser** globe icon.
* If prompted for a password, enter: `101`

### 3. Using the Desktop
* **Launchers**: Double-click the **Terminal** or **Wireshark** icons on the desktop.
* **Menu**: Right-click anywhere on the desktop or click the Application menu in the top panel to find installed utilities.
* **Challenges**: Your challenge materials are available in the **Challenges** folder on the desktop.

> [!NOTE]
> **Wireshark in Codespaces**: Wireshark is running in a cloud virtual machine to analyze provided `.pcap` and `.pcapng` capture files. It cannot directly sniff your personal laptop's physical Wi-Fi network.

### 4. Stopping and Resuming
* **Pausing**: When your session ends, close the browser tab. Codespaces automatically suspends after an idle period to preserve your monthly quota.
* **Resuming**: Visit [github.com/codespaces](https://github.com/codespaces) at any time, find your Codespace, and click on it to resume right where you left off.

---

## Troubleshooting & Diagnostics

If the desktop does not appear or shows an error:
1. Open the integrated terminal in VS Code (`Ctrl+\`` or `Cmd+\``).
2. Check the desktop service status:
   ```bash
   supervisorctl -c /etc/bootcamp-supervisord.conf status
   ```
3. View the service logs:
   * **VNC Server Log**: `cat ~/.bootcamp/vnc.log`
   * **noVNC Gateway Log**: `cat ~/.bootcamp/novnc.log`
   * **Supervisor Log**: `cat ~/.bootcamp/supervisor.log`
4. Manually trigger a desktop restart:
   ```bash
   bash /usr/local/bin/bootcamp-start
   ```