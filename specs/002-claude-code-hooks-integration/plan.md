# Implementation Plan: Claude Code Hooks Integration

**Branch**: `002-claude-code-hooks-integration` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-claude-code-hooks-integration/spec.md`

## Summary

Integrate Claude Monitor with real Claude Code sessions by leveraging
the Claude Code hooks system. Hook scripts fire on session lifecycle
events (`SessionStart`, `Stop`, `PermissionRequest`, etc.) and send
state updates to the app via a Unix domain socket. The app replaces
the mock status provider with a hook-based provider that tracks
multiple sessions and aggregates their states into a single menu bar
icon: steady green (running), flashing orange (needs input), grey
(idle). A testable hook configuration and script are provided for
manual setup.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI (MenuBarExtra), AppKit (NSImage, NSBezierPath), Network.framework (NWListener for Unix socket)
**Storage**: N/A (in-memory session tracking only)
**Testing**: XCTest (unit tests for SessionManager, aggregate logic)
**Target Platform**: macOS 14.0 (Sonoma)+
**Project Type**: desktop-app (menu bar agent) + bash hook scripts
**Performance Goals**: < 50 MB memory, < 1% CPU, hook execution < 100ms
**Constraints**: No Dock icon, no network access (localhost Unix socket only), no elevated permissions
**Scale/Scope**: Single-user local app, up to ~10 concurrent Claude Code sessions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Native macOS Menu Bar App | ✅ PASS | Swift + SwiftUI, .app bundle, LSUIElement, no web wrappers |
| II. Extensible Data Architecture | ✅ PASS | SessionInfo model separates transport (socket events) from presentation (StatusState). New fields addable to StateEvent without modifying consumers. Multiple sessions tracked via SessionManager. |
| III. Clear Status Hierarchy | ⚠️ DEVIATION | Spec and user request: green is steady (not flashing). Constitution says "Flashing green." This is a deliberate user override. Recommend constitution PATCH amendment to align. Priority ordering (orange > green > grey) is maintained. |
| IV. Minimal Footprint | ✅ PASS | Network.framework (system library), Unix socket (no ports), hook scripts exit immediately. No elevated permissions, no external network. |
| V. Simplicity First | ✅ PASS | Single socket, single script, simple JSON protocol. No plugin system, no configuration UI. SessionManager is a flat dictionary, not an ORM. |

**Post-Phase 1 re-check**: All gates pass. Principle III deviation is documented and justified by explicit user instruction. Constitution amendment recommended.

## Project Structure

### Documentation (this feature)

```text
specs/002-claude-code-hooks-integration/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── socket-protocol.md  # Unix socket message contract
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
ClaudeMonitor/
├── ClaudeMonitorApp.swift       # Updated: swap MockStatusProvider → HookStatusProvider
├── StatusState.swift             # Updated: running.isAnimated → false
├── StatusProvider.swift          # Unchanged
├── MockStatusProvider.swift      # Unchanged (kept for testing/demo)
├── StatusIconRenderer.swift      # Unchanged
├── SessionInfo.swift             # NEW: per-session state model
├── StateEvent.swift              # NEW: Codable struct for socket messages
├── SessionManager.swift          # NEW: tracks sessions, computes aggregate
├── HookStatusProvider.swift      # NEW: StatusProvider backed by socket listener
├── SocketListener.swift          # NEW: NWListener wrapper for Unix socket
├── Resources/
│   └── Info.plist

scripts/
└── claude-monitor-hook.sh       # NEW: bash hook script for Claude Code
```

**Structure Decision**: Continue with existing flat structure in
`ClaudeMonitor/`. New files added alongside existing ones. Hook
script placed in `scripts/` at repo root (shipped with the app,
user copies to `~/.claude/hooks/`).

## Complexity Tracking

| Deviation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Green not flashing (Constitution III) | User explicitly requested steady green | Flashing green is distracting for a "working normally" state; user finds it unnecessary |
