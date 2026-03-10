# Implementation Plan: Menu Bar App with Mock Status Cycle

**Branch**: `001-menu-bar-mock-status` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-menu-bar-mock-status/spec.md`

## Summary

Create a native macOS menu bar app that displays a colored circular
icon cycling through three mock states (idle/grey → running/flashing
green → attention/flashing orange) on a 3-second interval. The app
runs as a background agent (no Dock icon) with a minimal dropdown
menu. Architecture separates status data source from presentation
via a `StatusProvider` protocol to enable future replacement with
real Claude Code monitoring.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI (MenuBarExtra), AppKit (NSImage, NSBezierPath)
**Storage**: N/A
**Testing**: XCTest (optional for MVP)
**Target Platform**: macOS 14.0 (Sonoma)+
**Project Type**: desktop-app (menu bar agent)
**Performance Goals**: < 50 MB memory, < 1% CPU
**Constraints**: No Dock icon, no network access, no elevated permissions
**Scale/Scope**: Single-user local app, 1 screen (menu bar icon + dropdown)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Native macOS Menu Bar App | ✅ PASS | Swift + SwiftUI MenuBarExtra, LSUIElement, .app bundle |
| II. Extensible Data Architecture | ✅ PASS | StatusProvider protocol separates transport from presentation; StatusState enum is the versioned data model |
| III. Clear Status Hierarchy | ✅ PASS | Three states with defined priority: attention > running > idle |
| IV. Minimal Footprint | ✅ PASS | No dependencies beyond system frameworks; timer-based, no polling external resources |
| V. Simplicity First | ✅ PASS | Minimal code: one App struct, one observable state class, one protocol, one mock provider |

**Post-Phase 1 re-check**: All gates still pass. No violations introduced.

## Project Structure

### Documentation (this feature)

```text
specs/001-menu-bar-mock-status/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
ClaudeMonitor/
├── ClaudeMonitorApp.swift       # @main App struct with MenuBarExtra
├── StatusState.swift             # StatusState enum (idle, running, attention)
├── StatusProvider.swift          # StatusProvider protocol
├── MockStatusProvider.swift      # Mock implementation cycling states
├── StatusIconRenderer.swift      # NSImage generation for colored circles
├── Info.plist                    # LSUIElement = YES
└── Assets.xcassets/              # App icon (optional for MVP)

ClaudeMonitor.xcodeproj/          # Xcode project file
```

**Structure Decision**: Single Xcode project at repository root.
No separate `src/` or `tests/` directories — follows standard Xcode
macOS app conventions where source files live directly in the app
target group. Tests can be added as a separate test target later.

## Complexity Tracking

> No violations. No complexity justifications needed.
