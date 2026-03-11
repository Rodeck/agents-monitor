# Tasks: Status Notifications with Window Focus

**Input**: Design documents from `/specs/003-status-notifications/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the feature specification. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Extend existing data model with parent application context and set up the AppDelegate required for notification handling

- [x] T001 [P] Extend StateEvent with optional `ppid: Int?` and `app: String?` fields in ClaudeMonitor/StateEvent.swift
- [x] T002 [P] Extend SessionInfo with optional `parentPid: Int?` and `parentApp: String?` fields in ClaudeMonitor/SessionInfo.swift
- [x] T003 Update SessionManager.handleEvent() to pass parentPid and parentApp from StateEvent to SessionInfo in ClaudeMonitor/SessionManager.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Add attention transition callback `onAttention: ((SessionInfo) -> Void)?` to SessionManager that fires when a session transitions to .attention state in ClaudeMonitor/SessionManager.swift
- [x] T005 Create AppDelegate class conforming to NSApplicationDelegate and UNUserNotificationCenterDelegate, set as UNUserNotificationCenter delegate in applicationDidFinishLaunching in ClaudeMonitor/AppDelegate.swift
- [x] T006 Add `@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate` to ClaudeMonitorApp struct in ClaudeMonitor/ClaudeMonitorApp.swift
- [x] T007 Extend hook script to capture terminal PID (grandparent of hook process via `ps -o ppid= -p $PPID`) and app bundle identifier (via `lsappinfo`), add ppid and app fields to JSON payload in scripts/claude-monitor-hook.sh

**Checkpoint**: Foundation ready - data model extended, AppDelegate wired, hook script captures parent app info

---

## Phase 3: User Story 1 - Receive Notification When Session Needs Attention (Priority: P1) MVP

**Goal**: Display a macOS desktop notification when a Claude Code session transitions to the attention state, showing the project name

**Independent Test**: Start a Claude Code session, trigger a permission prompt, verify a macOS notification banner appears with the project directory name within 2 seconds

### Implementation for User Story 1

- [x] T008 [US1] Create NotificationManager class with UNUserNotificationCenter permission request (requestAuthorization with .alert, .sound) and notification sending method in ClaudeMonitor/NotificationManager.swift
- [x] T009 [US1] Implement notification content per UI contract: title "Claude needs attention", body as last path component of cwd, sound UNNotificationSound.default, category "SESSION_ATTENTION", userInfo with sessionId/workingDir/parentPid/parentApp in ClaudeMonitor/NotificationManager.swift
- [x] T010 [US1] Add notification coalescing via `lastNotificationTime: [String: Date]` dictionary — skip notification if same session was notified within 5 seconds, clean up entries when sessions are removed in ClaudeMonitor/NotificationManager.swift
- [x] T011 [US1] Implement willPresent delegate method in AppDelegate to return [.banner, .sound] so notifications display while menu bar app is "foreground" in ClaudeMonitor/AppDelegate.swift
- [x] T012 [US1] Wire NotificationManager to SessionManager.onAttention callback in HookStatusProvider so attention transitions trigger notifications in ClaudeMonitor/HookStatusProvider.swift
- [x] T013 [US1] Register UserDefaults default for "notificationsEnabled" as true in AppDelegate.applicationDidFinishLaunching, check preference before sending notification in NotificationManager in ClaudeMonitor/AppDelegate.swift and ClaudeMonitor/NotificationManager.swift

**Checkpoint**: At this point, notifications appear when Claude Code sessions need attention. Clicking them does nothing yet (handled in US2)

---

## Phase 4: User Story 2 - Click Notification to Focus the Correct Window (Priority: P1)

**Goal**: Clicking a notification activates the correct Terminal.app, VS Code, or iTerm2 window containing the Claude Code session

**Independent Test**: Trigger a notification from a session running in Terminal.app, click the notification, verify Terminal.app comes to the foreground with the correct window focused

### Implementation for User Story 2

- [x] T014 [US2] Create WindowFocusManager with focusWindow(processId:bundleIdentifier:workingDirectory:) method that implements the two-tier approach: app activation via NSRunningApplication.activate() and window targeting via AXUIElement in ClaudeMonitor/WindowFocusManager.swift
- [x] T015 [US2] Implement Accessibility permission check: AXIsProcessTrusted() before window targeting, fall back to app-level activation if not granted, prompt with AXIsProcessTrustedWithOptions on first click in ClaudeMonitor/WindowFocusManager.swift
- [x] T016 [P] [US2] Implement Terminal.app window matching: use AXUIElementCreateApplication(pid), enumerate kAXWindowsAttribute, match window by kAXTitleAttribute containing working directory name, raise with kAXRaiseAction in ClaudeMonitor/WindowFocusManager.swift
- [x] T017 [P] [US2] Implement VS Code window matching: enumerate AX windows, match by title containing project directory name (last path component of cwd), raise matched window in ClaudeMonitor/WindowFocusManager.swift
- [x] T018 [P] [US2] Implement iTerm2 window matching: enumerate AX windows, match by title containing working directory or session name, raise matched window in ClaudeMonitor/WindowFocusManager.swift
- [x] T019 [US2] Implement fallback chain: if Accessibility unavailable or no window title match, activate app via NSRunningApplication; if process not running, activate by bundle ID via NSWorkspace in ClaudeMonitor/WindowFocusManager.swift
- [x] T020 [US2] Implement didReceive notification response delegate in AppDelegate: extract sessionId/parentPid/parentApp/workingDir from userInfo, call WindowFocusManager.focusWindow() in ClaudeMonitor/AppDelegate.swift

**Checkpoint**: At this point, clicking notifications focuses the correct terminal/editor window for Terminal.app, VS Code, and iTerm2

---

## Phase 5: User Story 3 - Notification Preferences (Priority: P2)

**Goal**: Users can toggle notifications on/off from the menu bar dropdown, with the preference persisting across app restarts

**Independent Test**: Toggle notifications off in the menu bar dropdown, trigger an attention state, verify no notification appears; re-enable and verify notifications resume

### Implementation for User Story 3

- [x] T021 [US3] Add "Notifications" toggle item with checkmark to the MenuBarExtra dropdown using @AppStorage("notificationsEnabled") binding in ClaudeMonitor/ClaudeMonitorApp.swift
- [x] T022 [US3] Add divider before the Notifications toggle and after session count, matching the UI contract layout in ClaudeMonitor/ClaudeMonitorApp.swift

**Checkpoint**: All user stories are now independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T023 Clean up coalescing dictionary entries in NotificationManager when SessionManager removes stale sessions (wire to session cleanup) in ClaudeMonitor/NotificationManager.swift and ClaudeMonitor/SessionManager.swift
- [x] T024 Handle edge case where notification is clicked after session has ended: still attempt window focus using cached parentPid/parentApp from userInfo in ClaudeMonitor/AppDelegate.swift
- [x] T025 Verify build compiles without warnings via `swift build -c release` and test full flow with bundle-app.sh
- [ ] T026 Run quickstart.md validation checklist (all 10 test scenarios)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001-T002 for extended data model) - BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion
- **US2 (Phase 4)**: Depends on Phase 2 completion. Can run in parallel with US1 but notification click wiring (T020) logically builds on US1's NotificationManager
- **US3 (Phase 5)**: Depends on Phase 2 completion. Can run in parallel with US1/US2 (only touches ClaudeMonitorApp.swift menu UI)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - no dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - T020 references AppDelegate from US1 but WindowFocusManager (T014-T019) is independent
- **User Story 3 (P2)**: Can start after Foundational - fully independent of US1/US2 (only reads preference that US1 checks)

### Within Each User Story

- Models/data before services
- Services before wiring/integration
- Core implementation before edge case handling

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T016, T017, T018 can run in parallel (app-specific matchers in same file but independent methods)
- US1 and US3 can be worked in parallel (different files: NotificationManager vs ClaudeMonitorApp menu)
- WindowFocusManager (T014-T019) can be built in parallel with NotificationManager (T008-T010)

---

## Parallel Example: User Story 1

```bash
# After Phase 2 foundational is complete, launch these in parallel:
Task: "T008 - Create NotificationManager class in ClaudeMonitor/NotificationManager.swift"
Task: "T011 - Implement willPresent delegate in ClaudeMonitor/AppDelegate.swift"

# Then sequentially:
Task: "T009 - Implement notification content in ClaudeMonitor/NotificationManager.swift"
Task: "T010 - Add coalescing in ClaudeMonitor/NotificationManager.swift"
Task: "T012 - Wire NotificationManager to SessionManager in ClaudeMonitor/HookStatusProvider.swift"
Task: "T013 - Register defaults and check preference in AppDelegate + NotificationManager"
```

## Parallel Example: User Story 2

```bash
# After WindowFocusManager base is created (T014-T015), launch app matchers in parallel:
Task: "T016 - Terminal.app window matching in ClaudeMonitor/WindowFocusManager.swift"
Task: "T017 - VS Code window matching in ClaudeMonitor/WindowFocusManager.swift"
Task: "T018 - iTerm2 window matching in ClaudeMonitor/WindowFocusManager.swift"

# Then sequentially:
Task: "T019 - Fallback chain in ClaudeMonitor/WindowFocusManager.swift"
Task: "T020 - didReceive delegate in ClaudeMonitor/AppDelegate.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T007)
3. Complete Phase 3: User Story 1 (T008-T013)
4. **STOP and VALIDATE**: Notifications appear when sessions need attention
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 -> Test independently -> Deploy/Demo (MVP!)
3. Add User Story 2 -> Test independently -> Deploy/Demo (notifications now clickable)
4. Add User Story 3 -> Test independently -> Deploy/Demo (user can toggle notifications)
5. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- New files: NotificationManager.swift, WindowFocusManager.swift, AppDelegate.swift
- Modified files: StateEvent.swift, SessionInfo.swift, SessionManager.swift, HookStatusProvider.swift, ClaudeMonitorApp.swift, claude-monitor-hook.sh
