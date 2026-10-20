---
name: dereks-agentic-skills
description: Derek's collection of reusable engineering skills. Use it to route a request to the relevant Android, multi-agent, worktree, release, document, or interaction skill.
---

# Derek's Agentic Skills

Use this root skill when the full collection is installed. Route work to the smallest relevant child skill; each child can also be installed independently.

| Request | Child skill |
| --- | --- |
| Android or Kotlin Multiplatform development | [android/SKILL.md](android/SKILL.md) |
| Multi-agent planning, dispatch, validation, or handoff | [multi-agent-orchestration/SKILL.md](multi-agent-orchestration/SKILL.md) |
| Worktree-based feature workflow | [worktree-workflow/SKILL.md](worktree-workflow/SKILL.md) |
| Release tags or CI/CD | [release-cicd/SKILL.md](release-cicd/SKILL.md) |
| Gesture-driven animation | [interaction-driven-animation/SKILL.md](interaction-driven-animation/SKILL.md) |
| Android design gallery or signing | [android-design-gallery-and-signing/SKILL.md](android-design-gallery-and-signing/SKILL.md) |
| Android architecture patterns | [philipp-android-skills/SKILL.md](philipp-android-skills/SKILL.md) |
| Document-to-Markdown conversion | [markdown-converter/SKILL.md](markdown-converter/SKILL.md) |

When a request spans multiple areas, load only the child skills that materially apply. Follow repository-level instructions in `AGENTS.md` when present.
