---
name: dereks-agentic-skills
description: Derek's collection of reusable engineering skills. Use it to route a request to the relevant Android, multi-agent, or interaction skill. Worktree, release and document skills live in agent-kit.
---

# Derek's Agentic Skills

Use this root skill when the full collection is installed. Route work to the smallest relevant child skill; each child can also be installed independently.

| Request | Child skill |
| --- | --- |
| Android or Kotlin Multiplatform development | [android/SKILL.md](android/SKILL.md) |
| Multi-agent planning, dispatch, validation, or handoff | [multi-agent-orchestration/SKILL.md](multi-agent-orchestration/SKILL.md) |
| Gesture-driven animation | [interaction-driven-animation/SKILL.md](interaction-driven-animation/SKILL.md) |
| Android design gallery or signing | [android-design-gallery-and-signing/SKILL.md](android-design-gallery-and-signing/SKILL.md) |
| Android architecture patterns | [philipp-android-skills/SKILL.md](philipp-android-skills/SKILL.md) |

The worktree workflow, release/CI-CD policy, markdown conversion and the global rules are in [hereisderek/agent-kit](https://github.com/hereisderek/agent-kit), not here.

When a request spans multiple areas, load only the child skills that materially apply. Follow repository-level instructions in `AGENTS.md` when present.
