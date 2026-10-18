---
name: worktree-workflow
description: >-
  Derek's standard workflow for feature, fix, and refactor work in a git repo with Worktrunk (`wt`): start in a new worktree on a new branch, work and commit there, then finish through a pull request or a local `wt merge`, and when merging to the default branch is allowed. Also covers what is automated (agent plugins, project hooks as a local CI gate) and how to turn it on. Use when starting any change that gets its own branch, when asked to create or switch worktrees, when finishing or merging such work, or when setting up worktree automation. Not for read-only investigation or small edits the user wants applied in place.
---

# Feature worktree workflow (Worktrunk)

The policy is in the always-loaded rule `worktrunk.md` (read it for approvals). This skill is the playbook. For `wt` flags, hooks, and config, the official `worktrunk` skill and `wt <command> --help` are the source of truth. Install hints per machine: the machine notes (`~/.agents/rules/99-machine.md`).

## 1. Decide: worktree or not

Use a worktree when the task is a feature, a bug fix, a refactor, or anything else that will be committed on its own branch and reviewed or merged.

Do not create one for: read-only work; small edits the user wants applied in place; a task whose branch and worktree already exist (resume it: `wt list`, then work in that path).

## 2. Start

```bash
command -v wt >/dev/null || echo "wt missing: fall back to plain git and tell the user"
wt list                                              # is there already a worktree for this task?
wt switch --create feat/<slug> --no-cd --format=json # branches from the default branch
```

- Branch names: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`, `docs/<slug>`; short, lowercase, hyphens.
- `--no-cd`: an agent session cannot change directory with the shell wrapper. The JSON gives `{"action","branch","path","created_branch","base_branch"}`. **Use `path` for everything after this**: `git -C <path> ...`, `wt -C <path> ...`, and tool calls with absolute paths under it. Do not hardcode or guess it (default is the sibling `<repo>.<branch>`, `/` becomes `-`).
- Start from something other than the default branch only when the user says so: `--base <ref>`.
- If it fails with "needs approval", stop and tell the user to run `wt config approvals add`. Never `--yes`.

## 3. Work

- Every edit and commit happens in the worktree path. Never commit to the default branch directly.
- Commit in coherent steps. Plain `git -C <path> commit`; use `wt step commit` only if the user configured `[commit.generation]`.
- Run the checks that fit the change (see `testing-policy.md`): the touched tests and linters, not the whole suite for a small tweak.
- Sub-agents: create each worktree up front with `--no-cd` and name the absolute path in the sub-agent's prompt. Never `isolation: "worktree"`.

## 4. Finish

Report: branch, worktree path, what changed, which checks ran and their result. Then offer the next step, once:

- **Pull request (default).** Push the branch and open a PR (`git -C <path> push -u origin <branch>`, then `gh pr create`). Pushing needs the user's yes unless they already asked you to commit and push; opening a PR is outward-facing, so ask unless they asked for it. The user merges the PR on GitHub.
- **Local merge.** `wt -C <path> merge`: runs pre-merge hooks, squashes, rebases onto the default branch, fast-forwards it, and removes the worktree and branch. It never pushes or fetches.

## 5. When merging to the default branch is allowed

All of these must hold:

1. The work is complete and does what was asked.
2. The checks that fit the change pass (pre-merge hooks pass, if the project has them).
3. Nothing is uncommitted, and the branch is rebased on the current default branch (`wt merge` does the rebase).
4. **The user said to merge.** "Merge it", "ship it", or an answer of yes to your offer count. "Commit and push" does not: it covers pushing the branch, not merging.

If the rebase hits a conflict, `wt merge` stops with the rebase open in the worktree. Resolve mechanical conflicts, tell the user about any conflict that needed a judgement call, then run `wt merge` again. Never `--no-verify`/skip hooks to get past a failing check.

After a local merge, confirm with `git log -3 <default-branch>` and `wt list`, then report. `wt merge` already removed the worktree and branch, so no separate `wt remove` is needed. After the user merges a PR, clean up with `wt remove <branch>` (ask first; `safe-commands.md` applies).

## 6. What is automated, and how to turn it on

| Piece | State | How |
|-------|-------|-----|
| Agents start features in a worktree and finish them this way | on, by the `worktrunk.md` rule and this skill | nothing to do |
| Claude Code creates worktrees through `wt` (instead of its own `agent-<id>` ones), and `wt list` shows agent activity | installed on the agent LXC and on the Mac (2026-10-04) | `wt config plugins claude install` (user config change: ask first) |
| Same for Codex, opencode, Pi (activity markers) | agent LXC: Claude, Codex, opencode installed; Pi added to `wt-startup.sh`. Mac: not installed | `wt config plugins <agent> install` |
| Checks gate the merge: `wt merge` refuses to merge if they fail | per project, only where a project has `.config/wt.toml` | below |
| LLM commit messages | per user, off | `[commit.generation]` in `~/.config/worktrunk/config.toml`, see the official skill (user config: propose, wait for consent) |

**Project hooks** (`.config/wt.toml`, checked in; may be edited as part of requested work). Derive the commands from the project (`package.json` scripts, `Makefile`, `pyproject.toml`, `Cargo.toml`) and verify they run before adding them. Comment why each hook exists. A typical start:

```toml
# .config/wt.toml
# New worktrees need dependencies before anyone can build or test in them.
[[pre-start]]
install = "npm ci"

# Local CI gate: `wt merge` only merges if these pass.
[[pre-merge]]
test = "npm test"
lint = "npm run lint"
```

Project hooks need the user's approval once (`wt config approvals add`, run by the user, who reviews each command). Tell them which commands you added and why, and that nothing runs until they approve.

## 7. Never

- `git worktree add`, `git-cow-worktree`, or harness-made `agent-<id>` worktrees.
- `wt merge`, `wt remove`, or a push without the approvals above. `--force`, `-D`, `--reap`, `--yes` unless the user asks for that flag.
- Merging a branch the user has not seen finished (no report) or whose checks you did not run.
