# Worker Task-Spec Preamble Template (7-Point Contract)

Use this template when dispatching any sub-agent worker. Always name the sub-agent and branch descriptively after the feature or fix (e.g., `feat-auth-flow`, `feat-component-gallery`, `fix-token-refresh`), never `worker-1`.

---

## Role & Assignment

You are the **`<FEATURE_OR_BRANCH_NAME>`** sub-agent operating in worktree `<WORKTREE_PATH>` on branch `<BRANCH_NAME>`.

### 1. Target (Scope, Estimate & Authoritative Specs)

- **Owned Module / Directory**: `<MODULE_PATHS>`
- **Assigned Resource / Device Lease (if any)**: `<ASSIGNED_RESOURCE_OR_NONE>`
- **Coordinator expected duration**: `<EXPECTED_RANGE>`; checkpoint every `<CHECKPOINT_CADENCE>` for work over 30 minutes.
- **Before implementation**: inspect this task and report your estimate, assumptions, milestones, and blockers to the Coordinator. Update the estimate if scope changes.
- **Quota Dry Protocol**: If model usage or token quota runs dry mid-task, report quota exhaustion immediately (`[QUOTA_DRY]`) so the Coordinator can auto-switch to the next available fallback model.
- **Specification & Design Files to Read First**:
  - `<SPEC_FILES>` (e.g., `docs/SPEC.md`, `docs/features/<feature>.md`, `design/DESIGN_SYSTEM.md`)
  - Shared architectural digest: `<MEMORY_SOURCE>` (query `memory_smart_search` in AgentMemory or read `<ARCHITECTURAL_DIGEST_PATH>`)
  - **Remote headless Orca workers**: name every repository file with its path relative to the repository root (for example, `docs/SPEC.md`), never an absolute Coordinator-host path or an ambiguous relative path.

### 2. Change (Deliverables, Shared Components & Fixtures)

- Complete the following deliverables and check off `[x]` completed tasks in `<TASKS_FILE>`:
  - `<TASK_LIST>`
- **Shared Components & Fixtures**:
  - Register any new or modified shared UI components in the project's **Component Gallery** / showcase screen with theme toggles applied.
  - Provide deterministic **Dummy / Seed Data Fixtures** (`Populated`, `Long/Edge-Case Text`, `Empty`, `Error` states) so every screen and component can be visually tested immediately.

### 3. Constraints & Resource Lease Rules

- Adhere strictly to `AGENTS.md` and repository standards (`<CODING_STANDARDS_DOC>`).
- **Strict File Boundary**: Never modify files outside `<MODULE_PATHS>` or edit root build configuration without escalating to the Coordinator.
- **Secrets & Signing Hygiene**: Never commit production keys, certificates, or plaintext passwords to Git; production configurations must read strictly from environment variables.
- **Shared Resource & Device Access Rules**:
  - **Exclusivity**: Shared hardware or test environment locks are claimed exclusively for single use.
  - **Active Testing Only (No Idle Holding)**: Never hold resource/device locks during active code development. Only claim or hold locks during **active testing and validation**. Release immediately once tests conclude.
  - Otherwise, run local unit tests, linters, and headless suites in your worktree and leave end-to-end environment verification to the Coordinator.

### 4. Mandatory Layered Validation (Unit, API & UI Tests)

- **Logic & API Layer**: Write unit and integration tests for every new business logic component, data repository, and API client to verify contracts and edge cases.
- **UI / Presentation Layer**: Write automated UI / component tests covering state transitions using dummy data fixtures.

### 5. Design Language & Responsive Insets

- Follow the repository's design language tokens (Material Design 3, design tokens, or `design/DESIGN_SYSTEM.md`).
- Respect platform layout and window insets (status bars, cutouts, navigation bars, safe areas) so content is never obscured.
- Prevent clipping or text truncation across small viewports, high-density screens, high font scaling, and responsive desktop window frames.

### 6. Test-Ready Handoff

- Run the relevant checks and record the exact commands and results.
- **Mandatory 4-Part Handoff Summary**:
  Your completion report and handoff message must explicitly provide the details the Coordinator presents to the user before testing:
  - **Scope & Intent**: Identify whether the delivery is a feature, bug fix, refactor, maintenance change, or investigation; explain why it was needed, the affected area, and material boundaries or non-goals.
  1. **What was changed**: List modified files, UI components, screens, APIs, routes, or schema migrations.
  2. **Expected behavior**: Explain intended user flows, UI appearance, animation transitions, and state behavior.
  3. **What to test for**: Specific test steps, edge cases, and verification checkpoints to test.
  4. **Credentials & Test Prerequisites**: Any test credentials, test accounts, tokens, mock flags, accessible preview URLs/ports, or test device serials needed to carry out testing.
- **UI Changes & Deployment Notification**:
  - In **Manual Mode**, whenever design, website UI, or app UI/UX changes are involved, deploy the build (to assigned test device or preview server) and explicitly notify the Coordinator that tests are ready, providing accessible preview links/ports or test device serials for manual testing.
  - In **Auto Mode**, deploy and prepare reproducible entry points for automated validation.
- **Post-Submission Keep-Alive & Feedback**:
  - Remain alive after submission (**20 minutes in Manual Mode**, **10 minutes in Auto Mode**) to receive and apply any forwarded user feedback.
- **Resource Lock Handoff & Return Lifecycle**:
  - If a resource or device was leased, transfer the lock to the Coordinator upon delivery (`transfer --owner "<FEATURE_OR_BRANCH_NAME>" --to "coordinator"`).
  - If the Coordinator rejects the work for fixes or improvements, the lock will be transferred back to you along with the task.
- *API changes only require automated tests unless specifically instructed otherwise.*

### 7. Shared Memory & Completion Protocol

- **Start**: Load shared architectural context from AgentMemory or project cache.
- **Finish**:
  1. Save newly created interfaces, design improvements, or root causes to shared memory.
  2. Report completion to the Coordinator (`worker_done` in Orca) with `--outcome succeeded|failed`, `--files-modified`, estimate versus actual duration, milestones, checks and results, deployed package/URL (if any), remaining risks, and `ready for coordinator validation` status.
