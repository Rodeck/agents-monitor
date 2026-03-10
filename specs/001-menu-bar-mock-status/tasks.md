# Tasks: Menu Bar App with Mock Status Cycle

**Input**: Design documents from `/specs/001-menu-bar-mock-status/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Xcode project initialization and basic structure

- [x] T001 Create Xcode project `ClaudeMonitor` as macOS App with SwiftUI lifecycle at repository root, deployment target macOS 14.0
- [x] T002 Configure `Info.plist` to set `LSUIElement = YES` (Application is agent) so the app does not appear in the Dock
- [x] T003 Remove default `ContentView.swift` and `WindowGroup` from the generated app template (will be replaced by MenuBarExtra)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create `StatusState` enum with cases `idle`, `running`, `attention` in `ClaudeMonitor/StatusState.swift` — include a `color` computed property returning `NSColor` (grey, green, orange) and an `isAnimated` computed property returning `Bool` (false for idle, true for running/attention)
- [x] T005 Create `StatusIconRenderer` in `ClaudeMonitor/StatusIconRenderer.swift` — a struct with a static method `makeIcon(color: NSColor, size: CGFloat = 18) -> NSImage` that draws a filled circle using `NSBezierPath(ovalIn:)` with `isTemplate = false`
- [x] T006 [P] Create `StatusProvider` protocol in `ClaudeMonitor/StatusProvider.swift` — requires a `currentStatus: StatusState` property; conforming types must be `@Observable` so SwiftUI can react to changes

**Checkpoint**: Foundation ready — StatusState, icon rendering, and provider protocol defined

---

## Phase 3: User Story 1 & 2 — Menu Bar Icon with Mock Status Cycle (Priority: P1) 🎯 MVP

**Goal**: App launches with a menu bar icon that cycles through idle (grey) → running (flashing green) → attention (flashing orange) on a 3-second loop. Clicking the icon shows a dropdown with app name and Quit.

**Independent Test**: Launch the app from Xcode. A grey circle appears in the menu bar within 1 second. Over 9+ seconds, observe the icon cycle through grey → flashing green → flashing orange → grey → repeat. Click the icon to see "Claude Monitor" and "Quit" menu items. App does not appear in Dock.

### Implementation

- [x] T007 [US1] [US2] Create `MockStatusProvider` in `ClaudeMonitor/MockStatusProvider.swift` — an `@Observable` class conforming to `StatusProvider` that uses `Timer.scheduledTimer(withTimeInterval: 3.0)` to cycle `currentStatus` through `idle → running → attention → idle` in a loop
- [x] T008 [US1] [US2] Update `ClaudeMonitorApp.swift` to use `MenuBarExtra` with `.menuBarExtraStyle(.menu)` — the label closure must render `Image(nsImage:)` using `StatusIconRenderer.makeIcon(color:)` driven by the provider's `currentStatus`; the content must include a disabled "Claude Monitor" button and a "Quit" button calling `NSApplication.shared.terminate(nil)`
- [x] T009 [US1] [US2] Add flashing animation logic in `ClaudeMonitorApp.swift` — when `currentStatus.isAnimated` is true, toggle a `Bool` on a 0.5-second timer to alternate between the colored icon and a transparent/clear icon; when `isAnimated` is false, show the static colored icon

**Checkpoint**: At this point, User Stories 1 and 2 are fully functional — the app launches as a menu bar agent with a cycling mock status icon

---

## Phase 4: User Story 3 — Quit the App (Priority: P2)

**Goal**: Clean app termination from the menu bar dropdown

**Independent Test**: Click the menu bar icon, select "Quit", verify the app terminates and the icon disappears with no orphaned processes

### Implementation

- [x] T010 [US3] Verify quit functionality in `ClaudeMonitorApp.swift` — ensure the "Quit" button's `NSApplication.shared.terminate(nil)` correctly stops all timers (in `MockStatusProvider` and flash timer) and terminates the app without leaving background processes; add `deinit` to `MockStatusProvider` to invalidate its timer

**Checkpoint**: All user stories functional — app launches, cycles status, and quits cleanly

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verification and cleanup

- [ ] T011 [P] Verify app runs for 10+ minutes without memory growth or CPU spikes (SC-003, SC-004 from spec) ⏳ MANUAL
- [ ] T012 [P] Verify icon renders correctly on Retina and non-Retina displays at standard menu bar size (~18×18 points) ⏳ MANUAL
- [ ] T013 Run through quickstart.md verification checklist in `specs/001-menu-bar-mock-status/quickstart.md` — confirm all items pass ⏳ MANUAL

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories 1 & 2 (Phase 3)**: Depends on Foundational phase completion
- **User Story 3 (Phase 4)**: Depends on Phase 3 (quit button already exists, this phase verifies/hardens it)
- **Polish (Phase 5)**: Depends on all user stories being complete

### Within Phase 3

- T007 (MockStatusProvider) must complete before T008 (App struct)
- T008 must complete before T009 (flash animation)

### Parallel Opportunities

- T005 and T006 can run in parallel (different files, no dependencies)
- T011 and T012 can run in parallel (independent verification tasks)

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006)
3. Complete Phase 3: US1 & US2 (T007–T009)
4. **STOP and VALIDATE**: Build and run — verify icon appears, cycles, menu works
5. Continue to Phase 4 and 5

### Notes

- User Stories 1 and 2 are combined into a single phase because they are co-dependent (US1 = icon appears, US2 = icon cycles) and share the same implementation files
- Total: 13 tasks across 5 phases
- No test tasks generated (not explicitly requested in spec)
- Commit after each task or logical group
