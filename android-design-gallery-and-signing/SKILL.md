---
name: android-design-gallery-and-signing
description: Enforce Android design language and window insets (status bar, display cutout, bottom navigation bar, multi-density/resolution edge-clipping prevention), build an in-app themed Shared Component Gallery backed by deterministic dummy data, and configure consistent debug keystore reuse and environment-variable-driven production signing.
---

# Android Design System, Component Gallery, Dummy Data & Signing

Self-contained module governing four core pillars of the Android development cycle:

1. **Design Language & Window Inset Discipline** (Material Design 3 or user-specified design language, status bar, cutout, bottom navigation bar, and multi-screen/density clipping prevention)
2. **Themed Shared Component Gallery** (visual in-app showcase of all shared components across Light/Dark themes and states)
3. **Deterministic Dummy / Seed Data** (reusable development and QA fixtures so every screen and gallery component always has rich data to test)
4. **Signing Key Conventions** (shared debug keystore across builds/worktrees + git-excluded production signing via environment variables)

## When to Use

- Bootstrapping a new Android app or design system module (`Wave 0` / `core:designsystem`)
- Adding or modifying shared UI components, screens, or themes
- Creating realistic dummy/seed data for development, Compose previews, and live-device interactive testing
- Configuring or auditing `build.gradle.kts` signing configs (`debug` vs. `release`)

## 1. Design Language, Screen Matrix & Window Insets

### 1.1 Always Use an Explicit Design Language

- Default to **Material Design 3** (`androidx.compose.material3`) unless the user or repository specifies a custom design language (`design/DESIGN_SYSTEM.md`, HTML/CSS reference mocks, or Figma tokens).
- Define all colors, typography scales, shapes, spacing, and elevation tokens centrally in the theme module—never hardcode raw hex values or ad-hoc font sizes inside feature screens.

### 1.2 System Bars, Display Cutouts & Edge Clipping Prevention

Every screen must be edge-to-edge (`enableEdgeToEdge()`) and explicitly handle system window insets so no text, button, or card is ever obscured or cut off:

- **Status Bar**: Apply `WindowInsets.statusBars` (or `Scaffold` `contentWindowInsets`) to top app bars and headers; verify status bar icon contrast (`isAppearanceLightStatusBars`) in both Light and Dark themes.
- **Screen Cutout (Notch / Pinhole / Camera Cutout)**: Apply `WindowInsets.displayCutout` / `WindowInsets.safeDrawing` in both portrait and landscape so interactive elements and text never render underneath a camera cutout.
- **Bottom Navigation Bar**: Apply `WindowInsets.navigationBars` / `imePadding()` to bottom bars, sticky CTAs, FABs, and scrolling list `contentPadding` so neither 3-button navigation nor the gesture navigation bar overlaps bottom content.
- **Multi-Screen, Resolution & Density Checks**:
  - Use flexible layouts (`Modifier.weight`, `FlowRow`, `BoxWithConstraints`, adaptive `WindowWidthSizeClass`) and avoid fixed pixel/dp widths or single-line text without `maxLines` + `TextOverflow.Ellipsis`.
  - Verify on device across multiple screen sizes, resolutions, densities (`wm size`, `wm density`), and font scales (`font_scale 1.3`) using `$SKILL_ROOT/state-droid-remote-device/scripts/device-ui-audit.sh`.

### 1.3 Motion & Synchronized Animation Discipline

When two distinct UI elements have a synchronized animation (such as sharing the same trigger, e.g. user interaction or gesture):
- **Continuous, Not Discrete**: Motion must be continuous rather than snapping between discrete states or steps.
- **Unified Fling**: Fling gestures must use unified kinetic physics across both elements to maintain seamless momentum instead of disconnected or conflicting deceleration curves.
- **Smoothness**: The animation must remain fluid and smooth.
- **Precedence**: A direct instruction from the user takes precedence over this idle rule.

## 2. Shared Component Gallery (Visual Feedback Showcase)

Every Android app must include an in-app **Component Gallery** (accessible via a debug navigation route, developer drawer/menu, or dedicated debug `Activity` like `.debug.ComponentGalleryActivity`):

1. **Showcase Every Shared Component**: Render buttons, cards, input fields, chips, dialogs, top/bottom bars, badges, loading skeletons, and empty/error states in a single scrollable/tabbed catalog.
2. **Live Theme & State Controls**:
   - Provide an in-gallery selector for the real theme modes the app supports: at minimum **System**, **Light**, **Dark**, and **Dynamic Color** where the device/API supports it. Also expose any product color schemes (for example brand, expressive, high-contrast, or accessibility variants); do not reduce the gallery to a Light/Dark binary.
   - Model the selection as a theme configuration (mode, color scheme, and dynamic-color capability), then pass it to the app's real theme. The gallery must visibly distinguish an unavailable dynamic-color option from an active one.
   - Provide component-state controls for Default, Loading, Disabled, Error, and Long-Text Overflow so developers and the Coordinator can inspect tokens and states on a live device.
3. **Register New Shared Components Immediately**: Whenever a sub-agent creates or updates a shared component in `core:designsystem` or `core:ui`, it must add a showcase card for that component to the Component Gallery before marking its task done.
4. See `./assets/ComponentGalleryTemplate.kt` for a ready-to-adapt Compose implementation.

## 3. Deterministic Dummy & Seed Data for Development

Never leave development builds dependent on empty databases or unavailable live backends:

1. **Data Abstraction First, Development Fixtures via DI**:
   - Define a production-facing repository, use-case, or gallery data-source interface. Keep deterministic fixtures in `debug`, `core:testing`, or preview source sets, and inject that implementation in development builds through the project's DI mechanism (Hilt/Koin/manual composition root). Do not make an example fixture object the production data contract.
   - Keep the fixture catalog realistic and deterministic: standard items, long CJK/RTL/emoji text, multiline descriptions, numeric boundaries, timestamps, and user states.
2. **Debug Seed / Scenario Switcher**:
   - Provide a debug toggle or automatic seed initializer on fresh debug installs so launching the app immediately populates lists, detail views, and widgets with realistic data for interactive play-testing on device.
   - Support switching between **Populated**, **Empty State**, **Loading**, and **Error / Offline** scenarios during live device testing.

## 4. Signing Key Conventions (`debug` vs. `release`)

Run `./scripts/check-signing-safety.sh` to audit keystore configuration and Git hygiene.

### 4.1 Consistent Shared Debug Keystore

- Unless the user specifies a custom debug keystore, all debug builds across the main repo and all sub-agent git worktrees must use the **same shared debug keystore** (stored in `shared_debug_keystore` in `~/.config/android-skill-derek/config.json`, defaulting to `~/.android/debug.keystore`).
- Why this matters: Using a single consistent debug key guarantees that installing debug APKs from different branches or worktrees onto a test device (`./gradlew installDebug` or `adb install -r`) upgrades cleanly in place without throwing `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- If a repository defines a custom debug keystore path that does not exist on the machine, fall back automatically to `~/.android/debug.keystore` so builds never break on clean environments.

### 4.2 Production Signing Keys via Environment Variables Only

- **Never commit production signing keys** (`*.jks`, `*.keystore`, `*.p12`, or plaintext passwords) to Git. Ensure `.gitignore` blocks all production keystore files.
- Configure the `release` signing config in `build.gradle.kts` (see `./assets/signing-config.gradle.kts`) to read credentials strictly from **environment variables**:
  - `ANDROID_KEYSTORE_PATH`: Absolute path to the production `.jks` or `.keystore` file
  - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
  - `ANDROID_KEY_ALIAS`: Signing key alias
  - `ANDROID_KEY_PASSWORD`: Signing key password
- Guard the `release` signing block so that when `ANDROID_KEYSTORE_PATH` is not set locally, `./gradlew assembleDebug` and unit tests still configure and run cleanly without error.

## Directory Layout

- `SKILL.md`: Design language, inset rules, Component Gallery requirements, dummy data conventions, and signing key rules
- `scripts/check-signing-safety.sh`: Audits `.gitignore`, git-tracked files, shared debug keystore consistency, and release env vars
- `assets/signing-config.gradle.kts`: Drop-in Gradle Kotlin DSL signing configuration (shared debug key + env-var release signing)
- `assets/ComponentGalleryTemplate.kt`: Adaptable Jetpack Compose example showing theme configuration and an injected gallery data source; it is not a required production schema
