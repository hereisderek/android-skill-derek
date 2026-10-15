---
name: state-droid-remote-device
description: Discover, connect to, wake/unlock, lease, and verify Android apps on remote StageDroid devices (via mDNS _stagedroid._tcp, /skill, /status, /api/discovery, Central Smart ADB Proxy port 50370, or Virtual adbd ports 51001+), physical USB/Wireless ADB devices, or Google Android CLI virtual devices (AVDs). Handles sub-agent device pool assignment, automatic wake and passcode unlock, and multi-resolution/density/cutout/inset UI auditing while caching state in ~/.config/android-skill-derek/.
---

# StageDroid & Test Device Management (`state-droid-remote-device`)

Self-contained module for discovering and controlling remote Android devices via **StageDroid** ([`https://github.com/hereisderek/StageDroid`](https://github.com/hereisderek/StageDroid)), local USB/Wireless ADB devices, and Google Android CLI Virtual Devices (AVDs). Also manages sub-agent device pool leasing, sleeping/passcode-locked screen wakeup, and multi-density / window-inset UI verification.

## When to Use

- Discovering StageDroid servers via mDNS (`_stagedroid._tcp`), environment variables (`STAGEDROID_HOST`, `STAGEDROID_PORT`, `ADB_SERVER_SOCKET`), or local ports (`3000` / `3443`)
- Inspecting live StageDroid server capabilities via `GET /skill`, `GET /status` (`/status.json`), `GET /api/discovery`, and `GET /api/devices`
- Bridging remote StageDroid devices locally via Virtual `adbd` (`adb connect <host>:<adbPort>` on ports `51001+`) or the Central Smart ADB Proxy (`ADB_SERVER_SOCKET=tcp:<host>:50370` or `adb -H <host> -P 50370`)
- Managing a limited pool of physical/remote/virtual test devices and assigning leases to feature-named sub-agents or the Coordinator
- Waking a sleeping device, unlocking a PIN/passcode lockscreen, and auditing UI across screen sizes, densities, font scales, status bars, display cutouts, and bottom navigation bars

## 1. StageDroid Capability & Device Discovery Hierarchy

Always resolve StageDroid capability instructions in this order (automated by `./scripts/device-check.sh`). Device discovery may still query a reachable server for its live inventory; this precedence is for the instructions an agent follows:

1. **Latest Official StageDroid GitHub Source**:
   - First, fetch the current capability documentation from the official [`hereisderek/StageDroid`](https://github.com/hereisderek/StageDroid) repository. Prefer its current release/tag when one exposes `SKILL.md`; otherwise use the repository's default branch. Cache a successfully fetched copy and record the ref/URL used.
   - Treat the official source as authoritative when reachable. Do not assume the bundled snapshot or a previously cached live response is current.
2. **Live StageDroid Server (`GET /skill`)**:
   - If the official source is not available, query the connected server's `/skill` endpoint and cache the result. This is the next-best capability reference for the exact server in use.
3. **Bundled StageDroid Skill Snapshot (`./assets/stagedroid-snapshot.md`)**:
   - Use this only when neither the official source nor a live `/skill` response is available. State that its content may be stale before relying on it.
4. **Discover a Reachable Server and Its Devices**:
   - **Step 0 (mDNS on LAN)**: Browse `_stagedroid._tcp` (`dns-sd -B _stagedroid._tcp local.` on macOS / `avahi-browse -rt _stagedroid._tcp` on Linux). The TXT record carries `api`, `adbProxyPort`, `adbPortRange`, and `basePath`.
   - **Step 1 (Environment & Config)**: Check `STAGEDROID_HOST`, `STAGEDROID_PORT` (default `3000`), `STAGEDROID_HTTPS_PORT` (default `3443`), `STAGEDROID_ADB_PROXY_PORT` (default `50370`), `ADB_SERVER_SOCKET`, and `~/.config/android-skill-derek/config.json`.
   - **Step 2 (Local Fallbacks)**: Probe `http://127.0.0.1:3000/api/status` and `https://127.0.0.1:3443/api/status`.
5. **Local ADB & Google CLI Virtual Device Fallback (`avdmanager` / `emulator`)**:
   - When StageDroid is not running, fall back to local USB/Wireless `adb` devices or boot an Android Virtual Device using Google's Android SDK command-line tools (`sdkmanager`, `avdmanager`, `emulator`).

## 2. Bridging StageDroid Devices Locally

When StageDroid is available, choose the appropriate ADB bridge method from `./assets/stagedroid-snapshot.md`:

- **Method 0 — Virtual `adbd` (`adb connect <host>:<adbPort>`, ports `51001+` from `/api/discovery`)**:
  - Recommended for one-click Android Studio Run/Debug and JDWP breakpoints without disturbing `scrcpy` or the device's real `adbd` connection. Never `adb connect` directly to a device's raw Wi-Fi `adbd` port while StageDroid manages it.
- **Method A — Central Smart ADB Proxy (`export ADB_SERVER_SOCKET=tcp:<host>:50370`)**:
  - Recommended for agents and Gradle builds (`ADB_SERVER_SOCKET=tcp:<host>:50370 ./gradlew installDebug connectedAndroidTest`).
- **Method B/C — Non-Exclusive Flags (`adb -H <host> -P 50370 -s <serial> ...`)**:
  - Preserves visibility of local USB devices/emulators alongside remote StageDroid devices.
- **Fast Hardware Screenshots via StageDroid REST API**:
  - Prefer `curl -s http(s)://<host>:<port>/api/devices/<serial>/screenshot -o screen.png` over `adb exec-out screencap` when connected to StageDroid for zero-overhead capture.

## 3. Test Device Pool & Sub-Agent Lease Assignment

During multi-agent waves, test devices may be limited. The Coordinator manages device allocation across StageDroid devices, local physical devices, and Google CLI Virtual Devices via `./scripts/device-pool.sh`:

```bash
# List all StageDroid, local ADB, and virtual (AVD) devices with active lease owners
bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list

# Lease a free device (or auto-boot an AVD if all physical/remote devices are busy) for a named sub-agent
bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" lease --owner "feat-events-countdown"

# Release a lease after testing finishes
bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "feat-events-countdown"
```

## 4. Automatic Device Wake & Passcode Unlock

Before running instrumentation tests, launching the app, or capturing UI screenshots, wake the device and unlock any PIN/passcode lockscreen:

```bash
bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-wake-unlock.sh" --serial "<serial>"
```

- Sends `KEYCODE_WAKEUP` (`224`), dismisses keyguard, and checks `dumpsys window` / `dumpsys trust`.
- If the device requires a passcode and none is cached in `~/.config/android-skill-derek/devices.json`, ask the user once for the passcode, pass `--passcode "<code>"` so it is cached (`0600`) in the long-lived Coordinator cache, and unlock automatically.

## 5. Multi-Resolution, Density, Cutout & Window-Inset Auditing

Verify that the app's design language (Material Design 3 or custom `DESIGN_SYSTEM.md`) renders cleanly without text or edge clipping across screen sizes, densities, and system window insets:

```bash
bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-ui-audit.sh" \
  --serial "<serial>" \
  --package "<app_package_name>" \
  --output-dir "/tmp/ui-audit"
```

- Cycles through Compact Phone (`1080x1920@420dpi`), High-Density + Large Font (`1080x2400@480dpi`, `font_scale 1.3`), and Tablet/Foldable (`1800x2560@320dpi`), resetting hardware display settings afterward.
- Checks **status bar**, **screen cutout (notch/pinhole)**, and **bottom navigation bar** insets and flags any `uiautomator` node clipped at screen edges.

## Directory Layout

- `SKILL.md`: Official-GitHub-first StageDroid capability resolution, then live `/skill`, then local snapshot; discovery (`/status`, `/api/discovery`), ADB proxy bridging, device pool leasing, wake/unlock, and UI inset auditing
- `assets/stagedroid-snapshot.md`: Full snapshot of StageDroid's `SKILL.md` (used while `https://github.com/hereisderek/StageDroid` is private or offline)
- `assets/device-profile.example.json`: Example device pool and passcode cache configuration
- `scripts/device-check.sh`: Discovers StageDroid via mDNS/env/local ports, fetches `/skill` + `/status` + `/api/discovery`, and checks GitHub visibility
- `scripts/device-pool.sh`: Manages sub-agent device leases across StageDroid, physical ADB, and Google CLI AVD emulators
- `scripts/device-wake-unlock.sh`: Wakes sleeping screens and unlocks PIN/passcode lockscreens
- `scripts/device-ui-audit.sh`: Audits multiple screen sizes, densities, font scales, cutouts, system bars, and text/edge clipping
- `scripts/device-verify-gate.sh`: Full Coordinator Gate 2 verification runner
