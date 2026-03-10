# Feature Specification: Menu Bar App with Mock Status Cycle

**Feature Branch**: `001-menu-bar-mock-status`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Initialize application with mocked data. App shows idle icon for 3 seconds, then running green for 3 seconds, then flashing orange for 3 seconds, in repeat."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Launch App and See Status Icon (Priority: P1)

As a developer, I want to launch the Claude Monitor app and
immediately see a status icon appear in the macOS menu bar, so I
know the app is running and can glance at it for status.

**Why this priority**: Without a visible menu bar icon, the app has
no user-facing presence. This is the foundational capability.

**Independent Test**: Launch the app from Xcode or Finder. A small
circular icon appears in the menu bar within 1 second. The app does
not appear in the Dock.

**Acceptance Scenarios**:

1. **Given** the app is not running, **When** the user launches it,
   **Then** a small circular icon appears in the macOS menu bar
   (top-right area) within 1 second.
2. **Given** the app is running, **When** the user looks at the
   Dock, **Then** the app does NOT appear there (background agent
   mode).
3. **Given** the app is running, **When** the user clicks the menu
   bar icon, **Then** a simple dropdown appears showing "Claude
   Monitor" and a "Quit" option.

---

### User Story 2 - Observe Mock Status Cycle (Priority: P1)

As a developer, I want the menu bar icon to cycle through three
distinct visual states (idle → running → attention) on a timed
loop, so I can verify that all status indicators are visually
distinguishable and working correctly before wiring real data.

**Why this priority**: This is the core deliverable of this feature
— proving the visual indicator system works end-to-end with mock
data. Co-equal with US1 since both are needed for a usable result.

**Independent Test**: Launch the app, observe the icon for at least
9 seconds. It cycles: grey (3s) → flashing green (3s) → flashing
orange (3s) → grey (3s) → repeat.

**Acceptance Scenarios**:

1. **Given** the app just launched, **When** 0–3 seconds have
   elapsed, **Then** the icon displays as a solid grey circle
   (idle state).
2. **Given** the icon is in idle state, **When** 3 seconds have
   elapsed, **Then** the icon transitions to a flashing green
   circle (running state).
3. **Given** the icon is in running state, **When** 3 seconds have
   elapsed, **Then** the icon transitions to a flashing orange
   circle (attention state).
4. **Given** the icon is in attention state, **When** 3 seconds
   have elapsed, **Then** the icon transitions back to idle (grey)
   and the cycle repeats indefinitely.
5. **Given** any status state, **When** the user observes the icon,
   **Then** each state is visually distinct and identifiable at
   normal menu bar icon size (~18×18 points).

---

### User Story 3 - Quit the App (Priority: P2)

As a developer, I want to quit the app cleanly from the menu bar
dropdown, so I can stop the monitoring tool when I no longer need
it.

**Why this priority**: Essential for usability but secondary to the
core visual indicator functionality.

**Independent Test**: Click the menu bar icon, select "Quit", and
verify the app terminates and the icon disappears.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** the user clicks the icon
   and selects "Quit", **Then** the app terminates, the icon
   disappears from the menu bar, and no background processes remain.

---

### Edge Cases

- What happens if the app is launched while already running?
  **Assumption**: macOS handles single-instance enforcement; a
  second launch activates the existing instance.
- What happens if the system wakes from sleep mid-cycle?
  **Assumption**: The timer resets or continues from current state;
  no crash or visual glitch occurs.
- What happens at different display scales (Retina vs non-Retina)?
  **Assumption**: The icon renders correctly at all standard macOS
  display scales.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a circular icon in the macOS
  menu bar (NSStatusItem area) upon launch.
- **FR-002**: The app MUST run as a background agent with no Dock
  icon (LSUIElement mode).
- **FR-003**: The icon MUST cycle through three visual states on a
  fixed 3-second interval: idle (grey) → running (flashing green)
  → attention (flashing orange) → repeat.
- **FR-004**: The "flashing" animation MUST be a visible pulse or
  blink effect that distinguishes active states from the static
  idle state.
- **FR-005**: Clicking the menu bar icon MUST show a dropdown menu
  containing at minimum the app name and a "Quit" option.
- **FR-006**: Selecting "Quit" from the dropdown MUST terminate
  the app cleanly.
- **FR-007**: The status cycling MUST use a mock data source that
  can be replaced with a real data source in a future feature
  without modifying the icon rendering logic.

### Key Entities

- **StatusState**: Represents the current monitoring status. Has
  three possible values: idle, running, attention. Each value maps
  to a specific visual representation (color and animation).
- **StatusProvider**: The source of status information. In this
  feature, it is a mock provider that cycles through states on a
  timer. Future features will replace it with a real provider that
  reads Claude Code process state.

## Assumptions

- The mock cycle starts at "idle" on app launch.
- The 3-second interval is approximate and does not need
  millisecond precision.
- "Flashing" means a visible on/off or opacity pulse at roughly
  1–2 Hz (1–2 blinks per second).
- The icon size follows standard macOS menu bar conventions
  (~18×18 points).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The app launches and displays a menu bar icon within
  1 second of being opened.
- **SC-002**: All three status states (grey, green, orange) are
  visually distinguishable by a user at normal viewing distance
  from a Mac display.
- **SC-003**: The status cycle repeats continuously without
  interruption for at least 10 minutes of runtime.
- **SC-004**: The app consumes less than 50 MB of memory and less
  than 1% CPU during normal operation.
- **SC-005**: The app can be quit cleanly from the menu bar
  dropdown with no orphaned processes.
