# Implementation Plan: Status Notifications with Window Focus

**Branch**: `003-status-notifications` | **Date**: 2026-03-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-status-notifications/spec.md`

## Summary

Add macOS desktop notifications when Claude Code sessions need user input (attention state). Notifications display the project name and, when clicked, focus the correct terminal or editor window. Uses `UNUserNotificationCenter` for notification delivery, macOS Accessibility API (`AXUIElement`) for precise window targeting in Terminal.app, VS Code, and iTerm2, and `UserDefaults` for preference persistence. The hook script is extended to capture parent application identity.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, AppKit, UserNotifications.framework, ApplicationServices.framework (Accessibility API), Network.framework (existing)
**Storage**: UserDefaults (single boolean preference)
**Testing**: XCTest for unit tests; manual testing for notification delivery and window focusing
**Target Platform**: macOS 14 (Sonoma) and later
**Project Type**: Desktop app (native macOS menu bar agent)
**Performance Goals**: Notification delivery within 2 seconds of state change; window focus within 1 second of click
**Constraints**: < 50 MB memory, < 1% CPU (existing constraint from constitution)
**Scale/Scope**: 1-10 concurrent Claude Code sessions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Native macOS Menu Bar App | PASS | Uses Swift + SwiftUI/AppKit, runs as LSUIElement agent, no Electron/web frameworks |
| II. Extensible Data Architecture | PASS | Extends existing StateEvent/SessionInfo with optional fields (backward compatible). NotificationManager consumes data model without modifying it |
| III. Clear Status Hierarchy | PASS | Notifications triggered only by attention state, consistent with icon priority ordering. Menu bar icon behavior unchanged |
| IV. Minimal Footprint | PASS (with note) | Accessibility permissions required for window targeting — this is a new permission beyond the original "no elevated permissions" constraint. Justified: Accessibility is a standard macOS permission for productivity tools, requested on-demand (not at launch), and the app functions without it (falls back to app activation) |
| V. Simplicity First | PASS | Two new files (NotificationManager, WindowFocusManager). No plugin systems, no over-abstraction. Preference is a single UserDefaults boolean |

**Post-Phase 1 Re-check**: Constitution Principle IV has a minor tension with Accessibility permissions. This is documented in Complexity Tracking below.

## Project Structure

### Documentation (this feature)

```text
specs/003-status-notifications/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── hook-event-schema.md    # Extended event JSON schema
│   └── notification-ui-contract.md  # Notification content and menu UI
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
ClaudeMonitor/
├── ClaudeMonitorApp.swift       # MODIFY: Add notification toggle to menu, init NotificationManager
├── StatusState.swift             # No changes
├── StatusProvider.swift          # No changes
├── HookStatusProvider.swift     # MODIFY: Wire NotificationManager to attention events
├── SessionManager.swift          # MODIFY: Expose attention transition callback
├── SessionInfo.swift             # MODIFY: Add parentPid, parentApp fields
├── StateEvent.swift              # MODIFY: Add optional ppid, app fields
├── SocketListener.swift          # No changes
├── StatusIconRenderer.swift      # No changes
├── NotificationManager.swift    # NEW: UNUserNotificationCenter wrapper
├── WindowFocusManager.swift     # NEW: Accessibility-based window targeting
└── Resources/
    └── Info.plist                # No changes needed

scripts/
├── claude-monitor-hook.sh       # MODIFY: Capture ppid and app bundle ID
├── claude-monitor-hooks.json    # No changes
└── bundle-app.sh                # No changes
```

**Structure Decision**: Follows existing single-project flat structure in `ClaudeMonitor/`. Two new files added to the existing directory — no new subdirectories needed. Consistent with Principle V (Simplicity First).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Accessibility permission (Principle IV: "no elevated permissions") | Precise window/tab targeting for Terminal.app, VS Code, iTerm2 requires AXUIElement access | App-level activation without Accessibility works but cannot target a specific window when multiple are open. The core value of click-to-focus (US2) requires this. Permission is requested on-demand, not at launch, and the app degrades gracefully without it |
