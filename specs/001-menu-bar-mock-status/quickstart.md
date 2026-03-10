# Quickstart: Claude Monitor (Mock Status)

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (with Swift 5.9+)

## Build & Run

1. Open `ClaudeMonitor.xcodeproj` in Xcode.
2. Select the `ClaudeMonitor` scheme and `My Mac` as the run
   destination.
3. Press **Cmd+R** to build and run.

## What to Expect

- A small circular icon appears in the macOS menu bar (top-right).
- The app does NOT appear in the Dock.
- The icon cycles through three states on a loop:
  1. **Grey circle** (idle) — 3 seconds
  2. **Flashing green circle** (running) — 3 seconds
  3. **Flashing orange circle** (attention) — 3 seconds
  4. Returns to grey, repeats indefinitely.

## Menu

Click the menu bar icon to see:
- **Claude Monitor** — app name (informational)
- **Quit** — terminates the app

## Verify Success

- [ ] Icon appears in menu bar within 1 second of launch
- [ ] App does not appear in the Dock
- [ ] Grey, green, orange states are visually distinct
- [ ] Flashing is visible (~1 blink per second) for green/orange
- [ ] Cycle repeats smoothly for at least 1 minute
- [ ] Quit from menu works cleanly
