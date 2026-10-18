# AGENTS.md is the single source of agent instructions

- Repository-level agent guidance lives in `AGENTS.md`. It is the single source of truth.
- Do not create or maintain `CLAUDE.md`, `GEMINI.md`, or other tool-specific instruction files. If one exists, migrate its useful content into `AGENTS.md`, remove duplication, and resolve conflicts there.
- `README.md` is user-facing: what the project is, setup, usage, contributor workflow. Agent-facing operational instructions go in `AGENTS.md`.
- When `AGENTS.md` needs more structure, put focused guidance in an adjacent `agents/` directory (for example `agents/testing.md`, `agents/release.md`) and link to those files from `AGENTS.md`.
