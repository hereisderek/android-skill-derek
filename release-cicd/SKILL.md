---
name: release-cicd
description: This user's release-tagging conventions and required release CI/CD behavior — tag formats (v1.2.3 stable, beta_1.2.3 beta), the build/test/sign/package/notes/publish pipeline a release workflow must run, which distribution channel each tag type goes to, and how failures must be handled. Use this whenever the user wants to cut, tag, or ship a release or beta (for a Chrome extension, Android app, iOS app, npm package, or anything else), asks to set up or fix release CI/CD, mentions a version tag like v0.1.0 or beta_0.3.0, or is about to create/push/move any tag that looks like a release tag. Also consult it before creating or pushing a release tag yourself in any project — it requires explicit per-tag approval, which overrides any general assumption that tagging is a safe, low-stakes git operation.
---

# Release cycle and CI/CD

This is a personal policy, not project-specific: apply it in any repo where the user asks about cutting a release, publishing a beta, or setting up release automation — adapting the concrete build/sign/package steps to whatever that project actually is (Chrome extension, Android app, npm library, etc.), never inventing a step a project doesn't need.

## Why this exists

A release is one of the few actions in a repo that's genuinely hard to take back — once a tag is pushed, CI runs, and (for a stable release) it can end up in front of real users within minutes. The rules below exist to keep that irreversibility on a human's terms (explicit approval per tag, checks green before tagging) and to keep a broken build from becoming a broken release (fail loudly, never publish half of a release).

## Release tags

- **Stable**: `v<major>.<minor>.<patch>` — e.g. `v0.0.1`
- **Beta**: `beta_<major>.<minor>.<patch>` — e.g. `beta_0.0.3`
- Never `release_0.0.1` or other variants — the short, conventional `v`/`beta_` prefixes are what the CI trigger and this policy key off of.

**Approval gate (non-negotiable):** create and push a release tag only after the target commit has passed its required checks, and only with the user's explicit go-ahead for *that specific tag*. A prior release's approval doesn't carry forward — pushing a tag triggers a real, externally-visible pipeline, so treat it like any other action in that category: propose the tag name and commit, wait for a yes, then push. Never move or force-push an existing release tag; if one needs to change, that's a separate conversation with the user, not something to just do.

## What the release CI/CD workflow must do

Trigger: a push of a tag matching the release pattern. Set this up in whatever CI system the repo already uses (default to GitHub Actions if the repo has no CI yet and the user doesn't say otherwise).

1. **Verify the tag format** and determine stable vs. beta from its prefix. Fail fast on anything else rather than guessing which channel it belongs to.
2. **Build, test, sign, and package** the project's distributable artifact(s) — using the project's own build/test tooling, not a reinvented one. Signing only applies where the platform actually requires it (an Android AAB/APK, an iOS IPA); skip it entirely for platforms that don't have a signing step, like a Chrome extension zip or an npm package. For Android builds, combine with `$SKILL_ROOT/android-design-gallery-and-signing/SKILL.md` so production signing credentials are read strictly from environment variables (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) and never committed to Git.
3. **Upload the artifacts** to the workflow run, retained for the project's configured retention period (or the CI platform's default if the project hasn't set one).
4. **Generate release notes** from merged PRs, commits, and/or conventional commits since the previous *comparable* release — the previous stable tag for a stable release, the previous tag on the same channel for a beta. Use judgement on "comparable"; ask the user if it's genuinely ambiguous (e.g. first release on a channel).
5. **Create a GitHub Release** (or the CI platform's equivalent) with the generated notes and the produced artifacts attached.

## Distribution

**Stable (`v*`):**
- Publish to the platform's production release channel automatically, if the platform and repo configuration support safe automated publishing.
- If automated publishing is unavailable, unsafe, or needs a human's sign-off, create a **draft** release instead and say plainly what approval step remains and who needs to take it.
- Android specifically: upload to the configured Google Play track, defaulting to a draft/managed release. Only publish straight to production if the user has explicitly approved production publishing for that release.

**Beta (`beta_*`):**
- Same build/test/sign/package/notes/release pipeline as stable.
- Always mark the GitHub Release as a **prerelease**.
- Publish to the platform's non-production channel — Play internal/beta track, TestFlight, a browser store's unlisted/beta channel, npm's `next`/`beta` dist-tag, or whatever that platform's equivalent is.
- **Never** auto-promote a beta build to production. Shipping stable is always its own explicit, separately-approved release.

## Failure handling and reporting

If any check, build, sign, upload, or publish step fails:
- Do not publish a partial production release — an incomplete release is worse than a delayed one.
- Preserve build logs and artifacts wherever the CI platform allows it, so the failure can be diagnosed without re-running everything.
- Mark the workflow run as failed.
- Report clearly: which stage failed, the relevant log output, anything that *was* already created (a pushed tag, a draft release), and what manual recovery step the user needs to take.

## Applying this policy

- **Asked to set up or fix release CI/CD for a project**: read its existing CI config and build scripts first — extend what's already there rather than replacing a pipeline that's mostly correct. Write the workflow so it matches every section above, translated into that project's real tooling (its actual build/test commands, its actual signing/packaging needs, its actual store or registry).
- **Asked to cut a release** ("ship v1.2.0", "cut a beta", "release this"): confirm the target commit is on the intended branch and has passed CI, confirm the exact tag name with the user, and only create + push it once they say to proceed. That push is what should trigger everything else in this document — don't manually replicate the release steps by hand instead of tagging, and don't tag speculatively "to see if CI works."
