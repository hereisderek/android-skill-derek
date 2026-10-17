# Worker Task-Spec Preamble Template (7-Point Contract)

Use this template when dispatching any sub-agent worker. Always name the sub-agent and branch descriptively after the feature or fix (e.g., `feat-component-gallery`, `feat-events-countdown`, `fix-auth-token`), never `worker-1`.

---

## Role & Assignment

You are the **`<FEATURE_OR_BRANCH_NAME>`** sub-agent operating in worktree `<WORKTREE_PATH>` on branch `<BRANCH_NAME>`.

### 1. Target (Scope, Estimate & Authoritative Specs)

- **Owned Module / Directory**: `<MODULE_PATHS>`
- **Assigned Test Device Lease (if any)**: `<ANDROID_SERIAL_OR_NONE>`
- **Coordinator expected duration**: `<EXPECTED_RANGE>`; checkpoint every `<CHECKPOINT_CADENCE>` for work over 30 minutes.
- **Before implementation**: inspect this task and report your estimate, assumptions, milestones, and blockers to the Coordinator. Update the estimate if scope changes.
- **Quota Dry Protocol**: If model usage or token quota runs dry mid-task, report quota exhaustion immediately (`[QUOTA_DRY]`) so the Coordinator can auto-switch to the next available fallback model.
- **Specification & Design Files to Read First**:
  - `<SPEC_FILES>` (e.g., `docs/SPEC.md`, `docs/features/<feature>.md`, `design/DESIGN_SYSTEM.md`)
  - Shared architectural digest: `<MEMORY_SOURCE>` (query `memory_smart_search` in AgentMemory or read `~/.config/android-skill-derek/cache/<project>-digest.md`)

### 2. Change (Deliverables, Component Gallery & Dummy Data)

- Complete the following deliverables and check off `[x]` completed tasks in `<TASKS_FILE>`:
  - `<TASK_LIST>`
- **Shared Component Gallery & Dummy Data**:
  - Register every new or modified shared UI component in the in-app **Component Gallery** with Light/Dark theme toggles applied.
  - Provide deterministic **Dummy Data Fixtures** (`Populated`, `Long/Edge-Case Text`, `Empty`, `Error` states) so every screen and component can be visually tested immediately on device.

### 3. Constraints, Signing & Device Lease Rules

- Adhere strictly to `AGENTS.md`, `docs/standards/CODING_STANDARDS.md`, and `docs/ci-cd/TOOLCHAIN_GUIDELINES.md`.
- **Strict File Boundary**: Never modify files outside `<MODULE_PATHS>` or edit root Gradle files (`settings.gradle.kts`, `build.gradle.kts`, `gradle/libs.versions.toml`) without escalating to the Coordinator.
- **Signing Key Discipline**: Use the shared debug keystore (`~/.android/debug.keystore`) for all debug builds. Never commit production `.jks`/`.keystore` files or plaintext signing passwords to Git; release signing must read from environment variables (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).
- **Device Access & Exclusive Locking Rules**:
  - **Querying**: You may query connected devices at any time via `bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list` or `adb devices`. Any connected device is considered a test device unless the user explicitly instructed otherwise (user instruction takes precedence).
  - **Lease Assignment**: Run on-device commands (`./gradlew installDebug`, `connectedDebugAndroidTest`) only when holding an exclusive device lock. If the Coordinator omitted device information in this prompt, you may claim an available device directly via `bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" lease --owner "<FEATURE_OR_BRANCH_NAME>"`.
  - **Exclusivity**: A device lock is claimed exclusively for single use. Never run on a device held by another agent.
  - **Active Testing Only (No Idle Holding)**: Never hold the device lock during code development or writing. Only claim or hold the lock during **active testing and validation** on hardware.
  - Otherwise, run JVM unit tests (`./gradlew testDebugUnitTest`), Robolectric/Compose JVM tests, and `./gradlew lintDebug` in your worktree and leave on-device verification to the Coordinator.

### 4. Mandatory Layered Validation (Unit, API/Library & UI Tests)

- **API & Logic Layer**: Write unit and integration tests for every new ViewModel, repository, use case, parser, and domain calculator, and execute library/network request tests to verify API contracts.
- **UI Layer**: Write automated Compose UI / instrumentation tests covering state transitions using dummy data fixtures.

### 5. Design Language, Screen Sizes & Window Insets

- Follow the repository's design language (Material Design 3 by default or `design/DESIGN_SYSTEM.md`).
- Respect edge-to-edge system window insets (`WindowInsets.statusBars`, `WindowInsets.navigationBars`, `WindowInsets.displayCutout`, `WindowInsets.safeDrawing`) so neither the status bar, camera cutout, nor bottom navigation bar overlaps content.
- Prevent text truncation or edge cutoffs across small phones, high-density screens, `1.3x` font scaling, and tablets.

### 6. Test-Ready Handoff

- Run the relevant checks and record the exact commands and results.
- **Mandatory 4-Part Handoff Summary**:
  Your completion report and handoff message must explicitly provide the details the Coordinator presents to the user before testing:
  1. **What was changed**: List modified files, UI components, screens, APIs, routes, or schema migrations.
  2. **Expected behavior**: Explain intended user flows, UI appearance, animation transitions, and state behavior.
  3. **What to test for**: Specific test steps, edge cases, and verification checkpoints to test.
  4. **Credentials & Test Info**: Any test credentials, test accounts, tokens, mock flags, accessible preview URLs/ports, or test device serials needed to carry out testing.
- **Design, Website UI & App UI/UX Changes & Deployment Notification**:
  - In **Manual Mode**, whenever design, website UI, or app UI/UX changes are involved, deploy the build (to assigned test device or local preview server) and explicitly notify the Coordinator that tests are ready, providing accessible preview links/ports or test device serials for manual testing.
  - In **Auto Mode**, deploy and prepare reproducible entry points for automated validation.
- **Post-Submission Keep-Alive & Feedback**:
  - Remain alive after submission (**20 minutes in Manual Mode**, **10 minutes in Auto Mode**) to receive and apply any forwarded user feedback.
- **Device Lock Handoff & Return Lifecycle**:
  - If a device was leased, build, install, and launch the debug app on that device. Leave the requested screen or reproducible entry path ready for Coordinator testing; report package name, build variant, serial, and launch result.
  - Transfer the device lock to the Coordinator upon delivery: `bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" transfer --owner "<FEATURE_OR_BRANCH_NAME>" --to "coordinator"`.
  - If the Coordinator rejects the work for fixes or improvements, the device lock will be transferred back to you along with the task.
- If no device is assigned, create the installable artifact and report exact install/launch steps. State clearly that device validation remains pending.
- *API changes only require automated tests unless specifically instructed otherwise.*

### 7. Shared Memory & Completion Protocol

- **Start**: Load shared architectural context from AgentMemory or `~/.config/android-skill-derek/cache/`.
- **Finish**:
  1. Save newly created interfaces, design improvements, or root causes to shared memory.
  2. Report completion to the Coordinator (`worker_done` in Orca) with `--outcome succeeded|failed`, `--files-modified`, estimate versus actual duration, milestones, checks and results, deployed package/device (if any), remaining risks, and `ready for coordinator validation` status.
