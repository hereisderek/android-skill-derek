# Mobile Orchestration Verification Preset

Drop-in verification commands and lifecycle hooks for [`multi-agent-orchestration`](file:///Volumes/private/workspace/my-skills/android-skill-derek/multi-agent-orchestration/SKILL.md) when coordinating Android and Kotlin Multiplatform projects.

---

## Pluggable Environment Hooks

Configure these commands in your project's `.config/orchestration.env` or Coordinator environment:

```bash
# 1. Test Execution Command (runs under gradle daemon lock to prevent memory spikes)
VALIDATION_TEST_CMD="cd mobile && flock /tmp/dtm-gradle.lock ./gradlew :<module>:allTests"

# 2. Build & Assemble Command (produces debug APK for UI validation)
VALIDATION_DEPLOY_CMD="cd mobile && ./gradlew :androidApp:assembleDebug"

# 3. On-Device Smoke & Verification Command
VALIDATION_SMOKE_CMD="adb -s \"\${TEST_DEVICE:-\$ANDROID_SERIAL}\" install -r <path_to_apk> && adb shell am start -n <package>/<activity>"

# 4. Post-Merge Host Cleanup Command (stops gradle daemon to free memory)
POST_MERGE_CLEANUP_CMD="cd mobile && ./gradlew --stop"

# 5. Device Lock Release Command (if using shared hardware pool)
VALIDATION_LOCK_RELEASE_CMD="bash \"\$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh\" release --owner \"<validation-worker>\""
```

---

## Coordinator Mobile Validation Sequence

When the Coordinator executes Step 3 of the Cycle Workflow for a mobile task:

1. **Gradle Locking**: Ensure multi-agent Gradle tasks run under `flock /tmp/dtm-gradle.lock` to prevent parallel daemon contention and OOM errors on the host.
2. **Build Debug Artifact**: Execute `./gradlew :androidApp:assembleDebug`.
3. **Hardware / Device Pool Lease**:
   - Query online test devices from device pool or `adb devices`.
   - Install APK with `adb -s <serial> install -r <apk_path>`.
   - Launch target screen or Component Gallery route.
   - Inspect logcat for crashes/exceptions and capture screenshot.
4. **Post-Merge Daemon Discipline**: Always stop the Gradle daemon (`./gradlew --stop`) after merging to prevent idle memory consumption.
