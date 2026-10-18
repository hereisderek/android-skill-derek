---
name: agent-skills
description: General reusable agent skills and rules covering (1) Universal Multi-Agent Orchestration (`agent-orchestration`), (2) Interaction-Driven Animation (`interaction-driven-animation`), (3) Android & KMP Engineering Suite (`android`), (4) Android Design System, Component Gallery & Signing (`android-design-gallery-and-signing`), (5) Philipp Lackner KMP & Android Architecture (`philipp-android-skills`), (6) Worktrunk Git Worktree Workflow (`worktree-workflow`), (7) Package Release Tagging & CI/CD (`release-cicd`), and (8) Document & Media Markdown Conversion (`markdown-converter`).
---

# General Reusable Agent Skills (`agent-skills`)

A collection of framework-agnostic, open-source-ready skills and universal agent rules for pair programming, multi-agent orchestration, interactive mobile development, and git workflows.

## Skill Catalog

| Skill Name | Directory | Description | Install Flag |
| --- | --- | --- | --- |
| **`agent-orchestration`** | [`agent-orchestration/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/agent-orchestration/SKILL.md) | Universal multi-agent coordination across isolated git worktrees. Covers Manual vs. Auto modes, pre-review briefing, wait policies, timeboxed dispatch, keep-alive grace periods, quota routing, validation delegation to Gemini Flash, and the Coordinator Cycle Workflow (`/cycle`). | `--skill agent-orchestration` |
| **`interaction-driven-animation`** | [`interaction-driven-animation/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/interaction-driven-animation/SKILL.md) | 1:1 user touch/gesture tracking, momentum fling/spring on release, and instant halting without jump on touch interruption (Compose, SwiftUI, Web). | `--skill interaction-driven-animation` |
| **`android`** | [`android/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/android/SKILL.md) | Master Android & KMP development suite bundling design tokens, subtle in-app Component Gallery, live theme switching, Material You Expressive dynamic colour, and architecture conventions. | `--skill android` |
| **`android-design-gallery-and-signing`** | [`android-design-gallery-and-signing/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/android-design-gallery-and-signing/SKILL.md) | Material Design 3, window insets, subtle dev Component Gallery with real-time theme updating, Material You Expressive dynamic colour, deterministic dummy data, and safe keystores. | `--skill android-design-gallery-and-signing` |
| **`philipp-android-skills`** | [`philipp-android-skills/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/philipp-android-skills/SKILL.md) | Philipp Lackner's KMP & Android architecture suite (module structure, MVI, navigation, Koin DI, offline data, typed errors, compose components, testing, PR quiz). | `--skill philipp-android-skills` |
| **`worktree-workflow`** | [`worktree-workflow/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/worktree-workflow/SKILL.md) | Standard Worktrunk (`wt`) git worktree workflow for features, fixes, and refactors. | `--skill worktree-workflow` |
| **`release-cicd`** | [`release-cicd/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/release-cicd/SKILL.md) | SemVer release tagging (`v*` / `beta_*`) and CI/CD pipelines with explicit human approval. | `--skill release-cicd` |
| **`markdown-converter`** | [`markdown-converter/`](file:///Volumes/private/workspace/my-skills/android-skill-derek/markdown-converter/SKILL.md) | Converting PDF, Word, PowerPoint, Excel, HTML, CSV, images, audio, ZIPs, or EPubs to Markdown using Microsoft `markitdown`. | `--skill markdown-converter` |

---

## Universal Agent Rules (`rules/`)

Universal operational rules shared across all agent sessions:
- [`agents-md.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/agents-md.md): AGENTS.md as single source of truth
- [`deliverables-raw-syntax.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/deliverables-raw-syntax.md): Raw syntax formatting for copy-paste deliverables
- [`instruction-priority.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/instruction-priority.md): Instruction precedence hierarchy
- [`no-mannered-prose.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/no-mannered-prose.md): Plain, direct communication
- [`planning-and-review.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/planning-and-review.md): Planning and user review protocol
- [`safe-commands.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/safe-commands.md): Read-only, modification, and destructive command safety
- [`testing-policy.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/testing-policy.md): Testing discipline on changes
- [`worktrunk.md`](file:///Volumes/private/workspace/my-skills/android-skill-derek/rules/worktrunk.md): Worktrunk git worktree standards

---

## Installation via `skills` CLI

Every skill in this repository can be installed globally or locally using the standard `skills` CLI.

### Install All Skills as a Bundle
```bash
npx skills add hereisderek/android-skill-derek -g -y
```

### Install Specific Skills Individually
```bash
# Multi-agent orchestrator
npx skills add hereisderek/android-skill-derek -g --skill agent-orchestration -y

# Gesture-driven motion
npx skills add hereisderek/android-skill-derek -g --skill interaction-driven-animation -y

# Android & KMP complete suite
npx skills add hereisderek/android-skill-derek -g --skill android --full-depth -y

# Worktrunk workflow
npx skills add hereisderek/android-skill-derek -g --skill worktree-workflow -y
```
