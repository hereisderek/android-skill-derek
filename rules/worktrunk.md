# Git worktrees: use Worktrunk (`wt`)

Use Worktrunk ([worktrunk.dev](https://worktrunk.dev)) to create, switch, list, merge, and remove git worktrees whenever the `wt` CLI is installed. It replaces any other worktree convention: no plain `git worktree add`, no harness-made `agent-<id>` worktrees.

For flags, config, hooks, aliases, or troubleshooting, load the `worktrunk` skill (the official one from `max-sixty/worktrunk`) and run `wt <command> --help`. Do not guess flags.

## Availability

- Check `command -v wt` before the first worktree operation of a task.
- If `wt` is missing, fall back to `git worktree add` and say so. Do not install `wt` yourself. Tell the user how to install it on this machine (see the machine notes).

## Standard workflow (playbook: the `worktree-workflow` skill)

- **Start.** For a feature, bug fix, refactor, or any change that gets its own review or merge, create a worktree first on a new branch from the default branch (`wt switch --create <type>/<slug> --no-cd`; types `feat`, `fix`, `chore`, `docs`) and do all work and commits there. Never commit to the default branch directly. Skip the worktree for read-only work, for small edits the user wants applied in place, and when the current branch is already this task's branch.
- **Finish.** Run the checks that fit the change, commit, report, and offer the next step: a pull request (default) or a local `wt merge`.
- **Merge into the default branch** only when the work is complete, the relevant checks pass, nothing is uncommitted, and the user has said to merge. "Commit and push" is not "merge".

## Commands

| Task | Command |
|------|---------|
| Create a worktree on a new branch | `wt switch --create <branch>` (add `--base <ref>` to branch from something other than the default branch) |
| Create without changing directory (agent sessions, subagents) | `wt switch --create <branch> --no-cd` |
| Machine-readable result, including the worktree path | `wt switch --create <branch> --no-cd --format=json` |
| Open an existing branch or PR | `wt switch <branch>`, `wt switch pr:<N>` |
| List worktrees and their status | `wt list` |
| Commit staged changes | `wt step commit` only if the user has configured `[commit.generation]`; otherwise plain `git commit` |
| Target another repo | `wt -C <path> ...` (`-C` selects the repository, not the worktree; a command that names a branch already names its worktree) |

- Worktrees are addressed by branch name. Paths come from the configured template (default `../<repo>.<branch>`), so do not hardcode or invent them. Read the path from `--format=json` output or `wt list`.
- After `--no-cd`, run later commands with an explicit path (`git -C <path>`, `wt -C <path>`). The shell's working directory has not moved.
- Parallel sub-agents: create each worktree up front with `wt switch --create <branch> --no-cd`, then name the absolute path in the sub-agent prompt. Do not use `isolation: "worktree"` for this: it produces `agent-<id>` branches that bypass `wt` naming and hooks.

## Needs explicit user approval

- **Hook approvals.** `wt` refuses to run a project's `.config/wt.toml` hooks until the user approves them. If a command fails with "needs approval" or "Cannot prompt for approval", stop and tell the user to run `wt config approvals add`. Never pass `--yes`, and never run `wt config approvals add --yes`, to get past it.
- **`wt merge`.** It squashes, rebases, fast-forwards the local target branch, and removes the worktree and branch. Run it only when the user asks for a local merge. It never pushes or fetches. Prefer a pull request unless the user says otherwise.
- **`wt remove`.** It deletes a worktree, and the branch if merged. Follow `safe-commands.md`: explain, ask, wait for "yes". Only offer it when the work is merged or pushed and nothing is uncommitted. Never use `--force`, `-D`, or `--reap` unless the user asks for that flag.
- **Pushing.** Never push on your own: it needs the user's explicit yes. A request to commit and push is that yes for that push; it does not cover force-push, tags, or merging into the default branch.
- **User config.** Propose changes to `~/.config/worktrunk/config.toml` and wait for consent. Project config (`.config/wt.toml`) may be edited as part of requested work: comment why each hook exists, and flag destructive or network-fetching hook commands.

## Reporting

When a task that used a worktree is done, report: the branch name, the worktree path (from `wt list`), whether the worktree still exists, and what is committed, pushed, or left uncommitted.
