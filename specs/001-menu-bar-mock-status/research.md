# Research: Menu Bar App with Mock Status Cycle

**Date**: 2026-03-10
**Feature**: 001-menu-bar-mock-status

## R1: Menu Bar App Framework

**Decision**: Use `MenuBarExtra` (SwiftUI Scene API, macOS 13+)

**Rationale**: `MenuBarExtra` is Apple's first-party SwiftUI API for
menu bar apps. It integrates with the `@main` App protocol, supports
dynamic labels, and handles NSStatusItem lifecycle automatically.
No third-party dependencies needed.

**Alternatives considered**:
- Raw `NSStatusItem` via AppKit: More control but requires manual
  lifecycle management and AppDelegate setup. Overkill for MVP.
- `MenuBarExtraAccess` (third-party): Gives NSStatusItem access
  from MenuBarExtra. Not needed unless we hit MenuBarExtra limits.

## R2: Icon Rendering Approach

**Decision**: Programmatic `NSImage` via `NSBezierPath(ovalIn:)`
with `isTemplate = false`

**Rationale**: MenuBarExtra label supports `Image(nsImage:)` for
custom icons. SF Symbols with `foregroundStyle` are unreliable in
menu bar context — macOS forces template (monochrome) rendering.
Drawing a colored circle programmatically with `isTemplate = false`
preserves the intended color.

**Alternatives considered**:
- SF Symbol `circle.fill` with `.foregroundColor`: Unreliable color
  in menu bar due to template image treatment.
- Pre-rendered PNG assets: Works but less flexible for dynamic
  color changes needed for status states.

## R3: Flashing/Animation Mechanism

**Decision**: Toggle icon visibility via a 0.5-second Timer (swap
between colored circle and transparent/dimmed image)

**Rationale**: MenuBarExtra labels do not support true SwiftUI
animations (opacity, scale). Flashing is simulated by toggling
between two image states on a fast timer. At 0.5s interval this
produces a ~1 Hz blink, clearly visible.

**Alternatives considered**:
- NSStatusItem button-level animation: Requires dropping down to
  AppKit and managing the status item directly. Unnecessary
  complexity.
- Opacity-based animation: Not supported in MenuBarExtra label.

## R4: State Management

**Decision**: `@Observable` class (macOS 14+ / Swift 5.9+) observed
by the App struct

**Rationale**: The `@main` App struct's `body` returns a `Scene`,
not a `View`, so `.onReceive` is unavailable. An `@Observable`
class with `Timer.scheduledTimer` drives state changes, which the
App struct picks up via `@State` or direct observation.

**Alternatives considered**:
- `ObservableObject` with `@Published`: Works but `@Observable` is
  the modern replacement with less boilerplate.
- Timer in a View: The label closure is a View but has limited
  lifecycle hooks. Centralizing in an observable class is cleaner.

## R5: Menu Style

**Decision**: `.menuBarExtraStyle(.menu)` for MVP

**Rationale**: Renders SwiftUI Buttons as native NSMenu items. Simple,
familiar macOS UX. The `.window` style (popover panel) is better for
rich UI but unnecessary for MVP (just app name + Quit).

## R6: LSUIElement (Hide from Dock)

**Decision**: Set `LSUIElement = YES` in Info.plist

**Rationale**: Standard macOS mechanism for background agent apps.
No Dock icon, no app menu bar. Only the menu bar status item is
visible.

## R7: Project Setup

**Decision**: Xcode project with macOS App target (not SPM)

**Rationale**: Menu bar apps require an `.app` bundle with
Info.plist, code signing, and entitlements. SPM does not produce
`.app` bundles. Xcode manages the full build pipeline.

**Project details**:
- Xcode > New Project > macOS > App
- Interface: SwiftUI, Language: Swift
- Deployment target: macOS 14.0 (for `@Observable`)
- Replace `WindowGroup` with `MenuBarExtra` in App struct
- Add `LSUIElement = YES` to Info.plist
