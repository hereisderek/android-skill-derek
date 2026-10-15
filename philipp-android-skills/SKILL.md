---
name: philipp-android-skills
description: |
  Router for opinionated Android and Kotlin Multiplatform architecture conventions: project and module layout, Compose components, MVI presentation, Navigation Compose, Koin dependency injection, data layers, typed error handling, and unit tests. Use this skill whenever planning, creating, modifying, or reviewing Android/KMP code or architecture in a project that uses these conventions. Select and read the relevant specialized SKILL.md files in this package before making recommendations or code changes. Apply multiple specialized skills when a task crosses layers.
---

# Android / KMP Architecture Skills (`philipp-android-skills`)

This package is a router for the specialized skills in its subdirectories. Do not treat this file as a replacement for their detailed conventions.

## Workflow

1. Identify the requested layers or concerns.
2. Read the matching child `SKILL.md` file or files before responding or editing code.
3. Apply every relevant skill together. For example, a new feature commonly needs module structure, presentation MVI, navigation, DI, data layer, error handling, and unit testing.
4. Follow the child skills' guidance if it conflicts with a generic Android convention.

## Skill selection

| Concern | Read |
| --- | --- |
| Project setup, Gradle conventions, module boundaries, feature layout | `android-module-structure/SKILL.md` |
| Repository/data-source design, DTOs, Room, Ktor, mappers, offline-first | `android-data-layer/SKILL.md` |
| Typed `Result` values, `DataError`, mapping success or failure | `android-error-handling/SKILL.md` |
| Screen state, ViewModels, actions, events, Root/Screen composables, `SavedStateHandle` | `android-presentation-mvi/SKILL.md` |
| Reusable or extracted Compose components, design-system UI, previews | `android-compose-components/SKILL.md` |
| Type-safe Compose routes, feature graphs, cross-feature navigation | `android-navigation/SKILL.md` |
| Koin modules, dependency scopes, ViewModel injection, app wiring | `android-di-koin/SKILL.md` |
| In-process tests for ViewModels, use cases, reducers, validators, mappers, or formatters | `android-unit-testing/SKILL.md` |
| Adding or maintaining a reviewer quiz for a GitHub pull request | `pr-quiz/SKILL.md` |

## Common combinations

- New feature: `android-module-structure`, `android-presentation-mvi`, `android-navigation`, `android-di-koin`, and `android-unit-testing`; add `android-data-layer` and `android-error-handling` when the feature persists or fetches data.
- New screen: `android-presentation-mvi`, `android-navigation`, `android-compose-components`, and `android-unit-testing` as applicable.
- New repository or API/Room integration: `android-data-layer`, `android-error-handling`, `android-di-koin`, and `android-unit-testing`.
- Shared Compose control: `android-compose-components`; also read `android-presentation-mvi` only when the work affects a Root or Screen composable.

## Package layout

Keep this root `SKILL.md` beside the child skill folders. Install or copy the entire `philipp-android-skills` directory as one skill package so the relative paths above remain valid.
