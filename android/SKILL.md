---
name: android
description: Master Android & Kotlin Multiplatform (KMP) development suite covering (1) Material Design 3, subtle dev Component Gallery, dynamic theme updates & signing keys, (2) Interaction-driven animations (1:1 gesture tracking, momentum fling), (3) Philipp Lackner KMP & Android architecture conventions (module structure, MVI, navigation, Koin DI, offline-first data, error handling, reusable components, unit testing, PR quiz), and (4) Mobile orchestration verification presets. Use to architect, build, preview, or test any Android or KMP application.
---

# Android & KMP Engineering Suite (`android`)

Master playbook and router for modern Android and Kotlin Multiplatform (KMP) engineering. Covers foundation setup, design systems with live-themed in-app component galleries, gesture-driven motion, opinionated architectural patterns, and orchestration validation presets.

## When to Use

- Architecting, structuring, or reviewing Android and Kotlin Multiplatform projects
- Designing with Material Design 3, building subtle in-app Component Galleries with real-time theme updates and Material You Expressive dynamic colour, and managing safe signing keys
- Implementing gesture-triggered animations (collapsing headers, bottom sheets, carousels, swipe actions, pull-to-refresh) following `interaction-driven-animation`
- Building with Philipp Lackner's architecture conventions (MVI presentation, type-safe Navigation Compose, Koin DI, offline-first Room/Ktor data layer, typed Result error handling, unit testing with JUnit 5 + AssertK + Turbine, and PR quizzes)
- Integrating mobile-specific verification commands (`flock /tmp/dtm-gradle.lock`, APK assemble, device smoke testing) with `multi-agent-orchestration`

---

## Sub-Skills & Modules

| Module | Location | Description |
| --- | --- | --- |
| **Design, Gallery & Signing** | [`android-design-gallery-and-signing`](file:///Volumes/private/workspace/my-skills/android-skill-derek/android-design-gallery-and-signing/SKILL.md) | Material Design 3, window insets, subtle dev-build Component Gallery with live theme updating, Material You Expressive dynamic colour, deterministic dummy data, and debug/release keystores |
| **Interaction-Driven Motion** | [`interaction-driven-animation`](file:///Volumes/private/workspace/my-skills/android-skill-derek/interaction-driven-animation/SKILL.md) | 1:1 user touch tracking, momentum fling/spring on release, and instant halting without jump on touch interruption |
| **Architecture Router** | [`philipp-android-skills`](file:///Volumes/private/workspace/my-skills/android-skill-derek/philipp-android-skills/SKILL.md) | Opinionated KMP & Android architecture across 9 modular guides |
| **Module Structure** | `philipp-android-skills/android-module-structure` | Feature-layered modularization, version catalogs, and Gradle conventions |
| **MVI Presentation** | `philipp-android-skills/android-presentation-mvi` | Single State, sealed Action, Channel Event, Root/Screen composables, SavedStateHandle |
| **Navigation Compose** | `philipp-android-skills/android-navigation` | Type-safe Navigation Compose with `@Serializable` routes and per-feature nav graphs |
| **Dependency Injection** | `philipp-android-skills/android-di-koin` | Koin DI: feature modules, scoping, and `koinViewModel()` |
| **Offline-First Data Layer** | `philipp-android-skills/android-data-layer` | Repository design, DTOs, Room entities/DAOs, Ktor HttpClient, and caching |
| **Typed Error Handling** | `philipp-android-skills/android-error-handling` | Typed Result values, DataError, and error mapping |
| **Compose Components** | `philipp-android-skills/android-compose-components` | Reusable extracted composables, IconButton wrapping, relative sizing, preview matrix |
| **Unit Testing** | `philipp-android-skills/android-unit-testing` | JUnit 5 + AssertK + Turbine + fake repositories |
| **PR Quiz** | `philipp-android-skills/pr-quiz` | Interactive reviewer quizzes for GitHub pull requests |
| **Orchestration Preset** | [`mobile-orchestration-preset.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/android/mobile-orchestration-preset.md) | Pluggable verification commands for `multi-agent-orchestration` |

---

## Installation Options

- **Install as a Whole Suite**:
  ```bash
  npx skills add hereisderek/android-skill-derek -g --skill android --full-depth -y
  ```
- **Install Individual Sub-Skills**:
  ```bash
  npx skills add hereisderek/android-skill-derek -g --skill android-design-gallery-and-signing -y
  npx skills add hereisderek/android-skill-derek -g --skill philipp-android-skills -y
  npx skills add hereisderek/android-skill-derek -g --skill interaction-driven-animation -y
  ```
