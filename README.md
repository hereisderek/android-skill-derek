# agent-skills (General Reusable Skills)

Modular repository of general, reusable agent skills, universal agent rules, and specialized Android/KMP development workflows. Built to be completely **framework- and machine-agnostic**—installable individually or as an entire bundle via the `skills` CLI.

## Repository Structure

```text
agent-skills/
├── SKILL.md                                          # Root router for the full collection
├── README.md                                          # Documentation & installation guides
├── rules/                                             # Universal agent operational rules
│   ├── agents-md.md
│   ├── deliverables-raw-syntax.md
│   ├── instruction-priority.md
│   ├── no-mannered-prose.md
│   ├── planning-and-review.md
│   ├── safe-commands.md
│   ├── testing-policy.md
│   └── worktrunk.md
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
├── worktree-workflow/                                 # Feature worktree workflow with Worktrunk (wt)
│   └── SKILL.md
├── release-cicd/                                      # Release tagging (v* / beta_*) & CI/CD pipeline policy
│   └── SKILL.md
└── markdown-converter/                                # Document-to-Markdown conversion via markitdown
    └── SKILL.md
```

## Installation

### Install the Full Collection
```bash
npx skills add hereisderek/android-skill-derek -g -y
```

This installs the root router, **Derek's Agentic Skills**, and its child skills into the agent's skills directory.

### Install Individual Skills
```bash
# Multi-agent orchestration
npx skills add hereisderek/android-skill-derek -g --skill multi-agent-orchestration -y

# Gesture-driven animations
npx skills add hereisderek/android-skill-derek -g --skill interaction-driven-animation -y

# Android & KMP complete suite
npx skills add hereisderek/android-skill-derek -g --skill android --full-depth -y

# Git worktree workflow
npx skills add hereisderek/android-skill-derek -g --skill worktree-workflow -y
```
