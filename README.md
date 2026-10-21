# agent-skills (General Reusable Skills)

Modular repository of reusable agent skills: Android/KMP development, multi-agent orchestration and gesture-driven animation. Built to be completely **framework- and machine-agnostic**—installable individually or as an entire bundle via the `skills` CLI.

## Repository Structure

```text
agent-skills/
├── SKILL.md                                          # Root router for the full collection
├── README.md                                          # Documentation & installation guides
├── multi-agent-orchestration/                         # Multi-agent engineering workflow
│   ├── SKILL.md                                       # Coordinator vs. Worker, Manual/Auto modes, validation delegation
│   ├── scripts/detect-env.sh                          # Probes Orca, sub-agents, OpenSpec & AgentMemory
│   └── assets/worker-task-template.md                 # 7-Point Worker Task-Spec preamble template
├── interaction-driven-animation/                      # 1:1 user touch/gesture tracking, momentum fling (Compose, SwiftUI, Web)
│   └── SKILL.md
├── android/                                           # Master Android & KMP development suite
│   ├── SKILL.md                                       # Suite router & reference
│   └── mobile-orchestration-preset.md                 # Pluggable mobile verification commands
├── android-design-gallery-and-signing/                # Material 3 tokens, subtle dev Component Gallery, dynamic colour
│   ├── SKILL.md
│   ├── scripts/check-signing-safety.sh                # Verifies shared debug keystore & git-ignored release keys
│   └── assets/ComponentGalleryTemplate.kt             # Jetpack Compose themed Component Gallery + Dummy Data
├── philipp-android-skills/                            # Philipp Lackner Android & KMP Architecture Skills
│   ├── SKILL.md                                       # Architecture router for child skills
│   ├── android-module-structure/                      # Feature-layered modularization & Gradle conventions
│   ├── android-presentation-mvi/                      # MVI State/Action/Event & Root/Screen composables
│   ├── android-navigation/                            # Type-safe Navigation Compose routes & graphs
│   ├── android-di-koin/                               # Koin dependency injection modules & scoping
│   ├── android-data-layer/                            # Repositories, Room, Ktor, DTOs & offline-first
│   ├── android-error-handling/                        # Typed Result values & domain error mapping
│   ├── android-compose-components/                    # Reusable Compose UI components & design system reuse
│   ├── android-unit-testing/                          # JUnit 5 + AssertK + Turbine + fake repositories
│   └── pr-quiz/                                       # Interactive reviewer quizzes for GitHub pull requests
```

## Installation

### Install the Full Collection
```bash
npx skills add hereisderek/derek-agent-skills -g --full-depth -y
```

`--full-depth` installs every child skill (and `philipp-android-skills`' nested skills) as its own skill, plus the root router. Without it the CLI installs only the root skill with the children nested inside.

The global rules and the worktree, release and markdown skills are in [hereisderek/agent-kit](https://github.com/hereisderek/agent-kit) (`git clone` and `./install.sh`). Each skill lives in exactly one of the two repos, so installing both does not collide.

### Install Individual Skills
```bash
# Multi-agent orchestration
npx skills add hereisderek/derek-agent-skills -g --skill multi-agent-orchestration -y

# Gesture-driven animations
npx skills add hereisderek/derek-agent-skills -g --skill interaction-driven-animation -y

# Android & KMP complete suite
npx skills add hereisderek/derek-agent-skills -g --skill android --full-depth -y
```
