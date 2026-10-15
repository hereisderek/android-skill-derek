---
name: stagedroid
description: Connect to and control remote Android devices managed by StageDroid as if they were connected locally. Use when discovering StageDroid servers on the LAN (mDNS), discovering remote devices, bridging ADB via StageDroid's Central Smart ADB Proxy (port 50370), installing and launching apps on remote devices, inspecting logs/telemetry, or setting up remote debugging sessions.
license: MIT
metadata:
  author: StageDroid Team
  last-updated: '2026-10-15'
  keywords:
  - stagedroid
  - adb
  - remote-android
  - scrcpy
  - device-wall
  - android-debug
  - jdwp
  - mdns
---

This skill guides agents and developers on interacting with remote Android devices managed by **StageDroid**, bridging them to your local environment as if they were plugged into local USB.

---

## 1. Discovering Server Host & Ports

StageDroid's exact server IP and port may vary depending on the deployment (local machine, LAN server, or cloud host). Follow this resolution order to discover the target instance:

### Step 0: Auto-Discover via mDNS (LAN)
StageDroid advertises itself as `_stagedroid._tcp` (disable with `MDNS_ENABLED=false`; rename with `MDNS_NAME`). The TXT record carries `api`, `adbProxyPort`, `adbPortRange`, `basePath`. Browse and resolve it:
```bash
# macOS
dns-sd -B _stagedroid._tcp local.            # list instances
dns-sd -L "<instance name>" _stagedroid._tcp local.   # host + port
# Linux
avahi-browse -rt _stagedroid._tcp
```
Every StageDroid server also serves this document at `GET http://<host>:<port>/skill` (use it to learn what the server can do without this file).

For one JSON document with everything (app version, ports, mDNS, and every device with its `adb connect` command, Android Studio one-click info, central-proxy prefix, WebSocket tunnel, screenshot and stream links), call `GET /status` (alias `/status.json`). Full endpoint reference: `docs/API.md`.

Then read the connection info (device list with each device's `adbPort`):
```bash
curl -s http://<host>:<port>/api/discovery
# {"name":..., "lanAddresses":[...], "adbServerProxyPort":50370,
#  "devices":[{"serial":"...","model":"Pixel 8","androidVersion":"15","batteryLevel":80,"adbPort":51001}]}
```
Connect each device with `adb connect <host>:<adbPort>`, or use the Central Proxy (`ADB_SERVER_SOCKET=tcp:<host>:<adbServerProxyPort>`). mDNS only works on the same L2 network; across subnets/VPNs use the steps below.

### Step 1: Check Environment Variables
Inspect if the user has defined any of the following:
```bash
echo "Host: $STAGEDROID_HOST | Port: $STAGEDROID_PORT | ADB Proxy: $STAGEDROID_ADB_PROXY_PORT | Socket: $ADB_SERVER_SOCKET"
```
- `STAGEDROID_HOST`: Remote or LAN IP address of the StageDroid host (e.g., `192.168.1.50`).
- `STAGEDROID_PORT`: Web API HTTP port (default: `3000`).
- `STAGEDROID_HTTPS_PORT`: Web API HTTPS port (default: `3443`).
- `STAGEDROID_ADB_PROXY_PORT`: Central Smart ADB Proxy port (default: `50370`).
- `ADB_SERVER_SOCKET`: Full ADB socket descriptor (e.g., `tcp:192.168.1.50:50370`).

### Step 2: Test Local Fallbacks
If no environment variables are set, probe local instances:
```bash
curl -s http://127.0.0.1:3000/api/status || curl -k -s https://127.0.0.1:3443/api/status
```

### Step 3: Ask the User
If neither environment variables nor local servers respond, prompt the user:
> *"Please provide your StageDroid server IP or hostname (and port if not default 3000/3443)."*

### Step 4: Validate Connection & Discover Devices
Once the host is known, query the status endpoint to verify health and retrieve active ports:
```bash
curl -s http(s)://<host>:<port>/api/status
# Returns: {"success":true,"adbHost":"127.0.0.1","adbPort":5037,"adbServerProxyPort":50370,"activeDevices":4}
```

Query the full device inventory to obtain serials, models, Android versions, battery levels, and capabilities:
```bash
curl -s http(s)://<host>:<port>/api/devices
```

---

## 2. Bridging ADB (Access Devices Locally)

StageDroid operates a **Central Smart ADB Proxy** on port `50370` (`*:50370`), piping traffic directly into the host ADB server.

> [!NOTE]
> `adb connect <host>:<adbPort>` is supported through StageDroid's **Virtual `adbd`** responders (per-device ports `51001+`, listed in `/api/discovery` and on the device card). It does not touch the device's real `adbd` connection, so scrcpy sessions are unaffected. Never `adb connect` to a device's own Wi-Fi `adbd` port from a client while StageDroid holds that connection.

### Method 0: Native `adb connect` (Recommended for Android Studio Run/Debug)
```bash
adb connect <host>:<adbPort>   # adbPort from /api/discovery
adb devices
```
JDWP forwards bind on your local machine, so one-click Debug works.

### Method A: Global Session Export (Recommended for Agents & scripts)
Point your shell session directly at StageDroid's ADB proxy:
```bash
export ADB_SERVER_SOCKET=tcp:<host>:50370

# Verify: All remote devices now list as local devices!
adb devices
```
*Benefits:* Standard Android tools—including Android Studio, IntelliJ, Gradle, `adb`, Flutter, React Native, and Appium—will transparently recognize the remote devices without any special flags.

### Method B: Non-Exclusive Shell Alias (Preserves Local Devices)
If you have local USB devices or emulators on your client machine and want to access remote devices without shadowing local ones:
```bash
alias radb="adb -H <host> -P 50370"

# Usage:
radb devices
radb -s <serial> shell
```

### Method C: Single-Command Direct Flags
```bash
adb -H <host> -P 50370 devices
adb -H <host> -P 50370 -s <serial> <command>
```

---

## 3. Running Applications on Remote Devices

Direct app execution is **100% supported out of the box** over the StageDroid ADB bridge:

### 1. Install an APK
```bash
adb -H <host> -P 50370 -s <serial> install -r /path/to/app.apk
```

### 2. Launch an App Activity
```bash
adb -H <host> -P 50370 -s <serial> shell am start -n <package_name>/<activity_name>
# Example:
adb -H <host> -P 50370 -s <serial> shell am start -n com.example.myapp/.MainActivity
```

### 3. Stop or Clear App Data
```bash
# Force stop app
adb -H <host> -P 50370 -s <serial> shell am force-stop <package_name>

# Clear user data & cache
adb -H <host> -P 50370 -s <serial> shell pm clear <package_name>

# Uninstall
adb -H <host> -P 50370 -s <serial> uninstall <package_name>
```

### 4. Build & Run Directly via Gradle
In any Android project repository:
```bash
ADB_SERVER_SOCKET=tcp:<host>:50370 ./gradlew installDebug
```

### 5. Run Automated Tests
```bash
# Execute connected Android instrumentation tests
ADB_SERVER_SOCKET=tcp:<host>:50370 ./gradlew connectedAndroidTest

# Or trigger an instrumentation runner directly via adb
adb -H <host> -P 50370 -s <serial> shell am instrument -w <package_name>.test/androidx.test.runner.AndroidJUnitRunner
```

---

## 4. Debugging on Remote Devices (Status & How-To)

### Current State
* **One-click Android Studio debugging** works via `adb connect <host>:<adbPort>` (Virtual `adbd`), no tunnels needed. The approaches below apply only when using the Central Proxy (`50370`).
* **Logcat, dumpsys, bugreports, and shell debugging**: Fully supported out of the box.
* **Interactive IDE Step-Through Debugging (JDWP / Breakpoints)**:
  - When you click "Debug" (🪲) in Android Studio on your local laptop, Android Studio instructs the ADB server to forward a port to the on-device JDWP process (`host:forward:tcp:<port>;jdwp:<pid>`).
  - Because the ADB server is running on the **remote StageDroid host**, the forwarded TCP port binds on the **remote host machine** (`127.0.0.1:<port>`), not on your local laptop.
  - As a result, Android Studio's local debugger cannot connect to `localhost:<port>` by default without bridging that forwarded port to your local machine.

### How to Debug in Current State:

#### Approach 1: SSH Port Tunneling (Zero Code Changes)
If you have SSH access to the StageDroid host:
```bash
# 1. Forward the ADB SmartSocket proxy
ssh -L 50370:localhost:50370 -L 8700:localhost:8700 user@<host>

# 2. Point ADB locally
export ADB_SERVER_SOCKET=tcp:localhost:50370

# 3. Forward the target process JDWP to port 8700
adb -s <serial> forward tcp:8700 jdwp:<pid>

# 4. Attach Android Studio / IntelliJ:
# Run -> Attach to Process, or create a 'Remote JVM Debug' configuration on localhost:8700.
```

#### Approach 2: Remote JVM Debug Configuration
1. Start the app in debug-wait mode on the remote device:
   ```bash
   adb -H <host> -P 50370 -s <serial> shell am start -D -n <package>/<activity>
   ```
2. Find the application PID:
   ```bash
   adb -H <host> -P 50370 -s <serial> shell pidof <package>
   ```
3. Forward the JDWP port on the StageDroid host:
   ```bash
   adb -H <host> -P 50370 -s <serial> forward tcp:8600 jdwp:<pid>
   ```
4. In Android Studio:
   - Navigate to **Run > Edit Configurations > + > Remote JVM Debug**.
   - Host: `<host>`
   - Port: `8600`
   - Click **Debug**. Breakpoints will trigger and variable inspection works immediately!

---

## 5. Telemetry, Logcat & Screenshots

### Capture Logcat
```bash
# Stream live logs
adb -H <host> -P 50370 -s <serial> logcat -v time

# Dump recent logs to a local file
adb -H <host> -P 50370 -s <serial> logcat -d -v time > device_log.txt
```

### Full-Resolution Hardware Screenshots
```bash
# Option 1: Via StageDroid REST API (fastest, no adb exec overhead)
curl -s http(s)://<host>:<port>/api/devices/<serial>/screenshot -o screen.png

# Option 2: Via ADB bridge
adb -H <host> -P 50370 -s <serial> exec-out screencap -p > screen.png
```

### Direct Video Feed in Native Players
Stream sub-50ms H.264 video into VLC, mpv, or ffplay without opening a browser:
```bash
ffplay -probesize 32 -sync ext -fflags nobuffer -flags low_delay \
  "http://<host>:<port>/api/devices/<serial>/stream.raw?token=stagedroid_dev_token_placeholder"
```

---

## 6. Maintaining This Skill

This file is the capability reference served at `GET /skill`. Any feature added to StageDroid (endpoints, ports, env vars, protocols, MCP tools) must update this file in the same change.

## 7. Planned

* **Android Studio plugin download** from the server (`plugins/android-studio`; `/status` shows `links.androidStudioPlugin.available: false` until then).
* **MCP server**: expose discovery, device info, ADB connect, screenshot and input actions as MCP tools so agents need no curl/adb recipes (see `AGENTS.md` TODO).
