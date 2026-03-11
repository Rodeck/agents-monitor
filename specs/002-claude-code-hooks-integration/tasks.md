# Tasks: Claude Code Hooks Integration

**Input**: Design documents from `/specs/002-claude-code-hooks-integration/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/socket-protocol.md

**Tests**: Not explicitly requested in spec. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Create directories and file stubs for new source files

- [x] T001 Create `scripts/` directory at repository root for hook scripts
- [x] T002 Update `StatusState.isAnimated` to return `false` for `.running` (only `.attention` flashes) in `ClaudeMonitor/StatusState.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared data models and infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Create `StateEvent` Codable struct (fields: `sid`, `state`, `cwd`, `ts`) with JSON decoding in `ClaudeMonitor/StateEvent.swift` per `contracts/socket-protocol.md`
- [x] T004 [P] Create `SessionInfo` model (fields: `sessionId`, `state`, `workingDir`, `lastEventTime`) in `ClaudeMonitor/SessionInfo.swift` per `data-model.md`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 3 — Hook Configuration for Testing (Priority: P1) 🎯 MVP

**Goal**: Provide a working hook script and configuration that Claude Code instances can use to report state to the app

**Independent Test**: Copy hook config to `~/.claude/settings.json`, start a Claude Code session, and verify the hook script attempts to send messages to `/tmp/claude-monitor.sock`

### Implementation for User Story 3

- [x] T005 [US3] Create `scripts/claude-monitor-hook.sh` — bash script that: (1) receives mapped state as first arg (`running`/`attention`/`idle`), (2) reads JSON from stdin and extracts `session_id` and `cwd` via `jq` with pure-bash fallback, (3) sends compact JSON `{"sid":"...","state":"...","cwd":"...","ts":...}` to Unix socket at `/tmp/claude-monitor.sock` via `nc -U`, (4) exits 0 silently on any failure. See `contracts/socket-protocol.md` for message format and `research.md` R3 for design details.
- [x] T006 [US3] Create `scripts/claude-monitor-hooks.json` — sample hooks configuration block with all 8 hook events mapped: `SessionStart`→running, `UserPromptSubmit`→running, `PreToolUse`→running, `PostToolUse`→running, `Stop`→attention, `PermissionRequest`→attention, `Notification`→attention, `SessionEnd`→idle. Each entry uses command `~/.claude/hooks/claude-monitor-hook.sh <state>`. See `research.md` R2 for event mapping table.

**Checkpoint**: Hook script and config exist and can be manually installed. Can be tested independently by running `echo '{"session_id":"test","cwd":"/tmp"}' | bash scripts/claude-monitor-hook.sh running` (will fail to connect socket but should exit 0).

---

## Phase 4: User Story 1 — Live Session State in Menu Bar (Priority: P1) 🎯 MVP

**Goal**: App listens on Unix socket, receives hook events, and displays correct menu bar icon state (grey/green steady, orange flashing)

**Independent Test**: Launch app (grey icon), start a Claude Code session with hooks configured (icon turns green), wait for Claude to finish responding (icon turns orange), type a prompt (icon turns green), exit session (icon turns grey)

### Implementation for User Story 1

- [x] T007 [US1] Create `ClaudeMonitor/SocketListener.swift` — wrapper around `NWListener` (Network.framework) that: (1) creates and listens on Unix domain socket at `/tmp/claude-monitor.sock`, (2) removes stale socket file on startup, (3) accepts connections, reads data until EOF, (4) parses JSON into `StateEvent`, (5) calls a delegate/closure with parsed event, (6) cleans up socket file on deinit. See `research.md` R1 and R6.
- [x] T008 [US1] Create `ClaudeMonitor/SessionManager.swift` — observable class that: (1) maintains `[String: SessionInfo]` dictionary keyed by session ID, (2) exposes computed `aggregateState: StatusState` using priority ordering (attention > running > idle), (3) has `handleEvent(StateEvent)` method that creates/updates/removes sessions, (4) `idle` events remove the session from tracking. See `data-model.md` for aggregate logic.
- [x] T009 [US1] Create `ClaudeMonitor/HookStatusProvider.swift` — concrete `StatusProvider` implementation that: (1) owns a `SocketListener` and `SessionManager`, (2) wires socket events to `SessionManager.handleEvent`, (3) exposes `currentStatus` as `SessionManager.aggregateState`, (4) conforms to `@Observable` for SwiftUI reactivity.
- [x] T010 [US1] Update `ClaudeMonitor/ClaudeMonitorApp.swift` — replace `MockStatusProvider()` with `HookStatusProvider()` in `AppState`. Keep `MockStatusProvider` in codebase for future testing/demo use.

**Checkpoint**: Full end-to-end integration works for a single Claude Code session. Grey → green → orange → green → grey lifecycle is visible in menu bar.

---

## Phase 5: User Story 2 — Multiple Session Awareness (Priority: P2)

**Goal**: App correctly aggregates state across multiple concurrent sessions with priority ordering and stale session cleanup

**Independent Test**: Start two Claude Code sessions, have one wait for input while the other runs, verify icon shows orange. Resolve input, verify green. End one session, verify still green. End both, verify grey.

### Implementation for User Story 2

- [x] T011 [US2] Add stale session cleanup to `ClaudeMonitor/SessionManager.swift` — add a `Timer` (30-second interval) that removes sessions whose `lastEventTime` is older than 5 minutes. Update `aggregateState` after cleanup. See `research.md` R4.
- [x] T012 [US2] Add session list to menu dropdown in `ClaudeMonitor/ClaudeMonitorApp.swift` — display active session count and per-session state (e.g., "2 sessions active") in the menu dropdown below "Claude Monitor" label. This provides visibility into which sessions are tracked.

**Checkpoint**: Multiple concurrent sessions display correct aggregate icon. Stale sessions auto-clean after timeout.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Hardening and documentation

- [x] T013 Update `specs/002-claude-code-hooks-integration/quickstart.md` with any deviations discovered during implementation
- [x] T014 Run full quickstart.md validation checklist manually and document results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (`StatusState` fix) — BLOCKS all user stories
- **US3 (Phase 3)**: Depends on Phase 2 (needs `StateEvent` format defined) — can run in parallel with US1
- **US1 (Phase 4)**: Depends on Phase 2 (needs models) — can run in parallel with US3
- **US2 (Phase 5)**: Depends on Phase 4 (extends `SessionManager`)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US3 (Hook Config - P1)**: Can start after Foundational. No dependencies on US1/US2. Produces the hook script that US1 needs for end-to-end testing.
- **US1 (Live Session State - P1)**: Can start after Foundational. Needs US3's hook script for manual testing but not for code compilation.
- **US2 (Multiple Sessions - P2)**: Depends on US1 (extends SessionManager with cleanup timer and menu UI).

### Within Each User Story

- Models before services
- Services before app integration
- Core implementation before UI enhancements

### Parallel Opportunities

- T003 and T004 (Phase 2 models) can run in parallel
- US3 (Phase 3) and US1 (Phase 4) can start in parallel after Phase 2
- T005 and T006 (Phase 3 hook script and config) are sequential (config references script)

---

## Parallel Example: Foundational Phase

```bash
# Launch both model files together:
Task: "Create StateEvent Codable struct in ClaudeMonitor/StateEvent.swift"
Task: "Create SessionInfo model in ClaudeMonitor/SessionInfo.swift"
```

## Parallel Example: US3 + US1 Kickoff

```bash
# After Phase 2, launch both stories:
Task: "Create claude-monitor-hook.sh in scripts/"  (US3)
Task: "Create SocketListener.swift in ClaudeMonitor/"  (US1)
```

---

## Implementation Strategy

### MVP First (US3 + US1)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T004)
3. Complete Phase 3: US3 — Hook Configuration (T005-T006)
4. Complete Phase 4: US1 — Live Session State (T007-T010)
5. **STOP and VALIDATE**: Test single session lifecycle end-to-end
6. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US3 (Hook Config) + US1 (Live State) → Test independently → Deploy (MVP!)
3. Add US2 (Multiple Sessions) → Test independently → Deploy
4. Polish → Final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US3 and US1 are both P1 but US3 is an enabler (produces the hook script)
- The hook script uses `nc -U` for socket communication — verify `nc` supports `-U` on target macOS versions (it does on macOS 14+)
- `MockStatusProvider` is kept in the codebase for demo/testing — not deleted
- Constitution Principle III deviation (steady green): implemented in T002
