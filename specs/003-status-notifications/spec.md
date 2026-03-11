# Feature Specification: Status Notifications with Window Focus

**Feature Branch**: `003-status-notifications`
**Created**: 2026-03-11
**Status**: Draft
**Input**: User description: "Add desktop notifications similar to Slack messages for status changes. When notification is displayed and user clicks on it, the window with the terminal that needs attention should be focused. It can be terminal or VS Code depending on which instance needs attention."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Notification When Session Needs Attention (Priority: P1)

As a developer working in another app, I want to receive a macOS desktop notification when a Claude Code session needs my input, so I am alerted even when I am not looking at the menu bar icon.

**Why this priority**: This is the core value proposition. The menu bar icon is passive — notifications are active and interrupt-driven, ensuring users never miss a session that is waiting.

**Independent Test**: Start a Claude Code session, trigger a permission prompt, and verify a macOS notification banner appears with the session information.

**Acceptance Scenarios**:

1. **Given** a Claude Code session transitions to the "waiting for input" state, **When** the state change event is received by Claude Monitor, **Then** a macOS notification is displayed with a title indicating the session needs attention and a body showing the project/directory name
2. **Given** a notification is displayed, **When** the user reads the notification, **Then** the notification clearly identifies which session (by project or directory) needs attention
3. **Given** multiple sessions transition to "waiting for input" within a short time, **When** the notifications are generated, **Then** each session produces its own notification so the user can see all sessions that need attention
4. **Given** the user has macOS notification permissions disabled for Claude Monitor, **When** a session needs attention, **Then** the app gracefully handles the denial and continues operating (menu bar icon still works)

---

### User Story 2 - Click Notification to Focus the Correct Window (Priority: P1)

As a developer, I want to click a notification and have macOS bring the correct terminal or VS Code window to the foreground, so I can immediately provide input without manually hunting for the right window.

**Why this priority**: Without this, notifications are informational only. The click-to-focus behavior is what makes notifications actionable and saves the user time.

**Independent Test**: Trigger a notification from a Claude Code session running in Terminal.app, click the notification, and verify Terminal.app comes to the foreground with the correct window focused.

**Acceptance Scenarios**:

1. **Given** a notification is displayed for a session running in Terminal.app, **When** the user clicks the notification, **Then** Terminal.app is activated and the specific terminal window/tab for that session is brought to the foreground
2. **Given** a notification is displayed for a session running in VS Code's integrated terminal, **When** the user clicks the notification, **Then** VS Code is activated and the specific window for that project is brought to the foreground
3. **Given** a notification is displayed but the originating terminal window has been closed, **When** the user clicks the notification, **Then** the parent application is activated (best effort) and no crash or error occurs
4. **Given** a notification is displayed for a session running in an unsupported terminal emulator, **When** the user clicks the notification, **Then** the app makes a best-effort attempt to focus the application and does not crash

---

### User Story 3 - Notification Preferences (Priority: P2)

As a developer, I want to control when notifications are shown, so I can avoid notification fatigue during focused work or when I am actively watching the terminal.

**Why this priority**: Important for user experience but not essential for the core feature to function. Users can rely on macOS Do Not Disturb as an initial workaround.

**Independent Test**: Toggle the notification preference in the menu bar dropdown and verify that subsequent attention states do or do not produce notifications.

**Acceptance Scenarios**:

1. **Given** notifications are enabled (default), **When** a session transitions to "waiting for input", **Then** a notification is displayed
2. **Given** notifications are disabled via the menu bar dropdown, **When** a session transitions to "waiting for input", **Then** no notification is displayed but the menu bar icon still updates
3. **Given** the user re-enables notifications, **When** the next session transitions to "waiting for input", **Then** notifications resume

---

### Edge Cases

- What happens when the same session fires multiple "waiting for input" events in rapid succession? The app should coalesce duplicate notifications for the same session within a short window (e.g., 5 seconds) to avoid notification spam.
- What happens when the user clicks a notification after the session has already resumed or ended? The app should still attempt to focus the originating application window. If the window no longer exists, it activates the parent application.
- What happens when the originating application (Terminal, VS Code) is on a different macOS desktop/Space? macOS should switch to the correct Space when the application is activated (standard macOS behavior).
- What happens when the notification permission prompt appears for the first time? The app should request notification permissions on first launch or first notification attempt, with a clear explanation of why notifications are needed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a macOS notification when a Claude Code session transitions to the "waiting for input" (attention) state
- **FR-002**: Each notification MUST include the project or working directory name to identify which session needs attention
- **FR-003**: Clicking a notification MUST activate the originating application and bring the relevant window to the foreground. First-class supported applications are Terminal.app, VS Code, and iTerm2 (with app-specific window targeting). Other terminal emulators receive best-effort app-level activation only
- **FR-004**: The app MUST request macOS notification permissions from the user and handle permission denial gracefully
- **FR-005**: The app MUST coalesce duplicate notifications for the same session within a 5-second window to prevent notification spam
- **FR-006**: The app MUST provide a toggle in the menu bar dropdown to enable or disable notifications (enabled by default)
- **FR-007**: The notification preference MUST persist across app restarts
- **FR-008**: The app MUST NOT display notifications for sessions transitioning to "running" or "idle" states — only for the "attention" state
- **FR-011**: Notifications MUST use the default macOS notification sound; sound control is delegated to macOS System Settings per-app preferences (no in-app sound toggle)
- **FR-012**: The app MUST request macOS Accessibility permissions to enable precise window and tab targeting for first-class supported applications (Terminal.app, VS Code, iTerm2)
- **FR-009**: The app MUST include enough context in hook event data to identify the originating application and window (e.g., process ID, application name, or window identifier)
- **FR-010**: When the originating window cannot be found, the app MUST fall back to activating the parent application without crashing

### Key Entities

- **Notification**: A macOS user notification triggered by a session attention event, containing session identifier, project name, and originating application context
- **Window Reference**: Information needed to locate and focus the correct application window, including application identifier, process ID, and working directory
- **Notification Preference**: A persistent user setting controlling whether notifications are displayed

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Notifications appear within 2 seconds of a session entering the "waiting for input" state
- **SC-002**: Clicking a notification brings the correct application window to the foreground within 1 second
- **SC-003**: Users can identify which project needs attention from the notification content alone, without needing to open the app
- **SC-004**: Duplicate notifications for the same session are suppressed when events arrive within 5 seconds of each other
- **SC-005**: The notification toggle persists correctly across app restarts 100% of the time

## Clarifications

### Session 2026-03-11

- Q: Which terminal applications should have first-class window-targeting support? → A: Terminal.app, VS Code, and iTerm2 as first-class supported; other terminal emulators get best-effort app-level activation only
- Q: Should notifications play a sound? → A: Use the default macOS notification sound; user controls sound via System Settings per-app (no custom toggle needed)
- Q: Should the app request Accessibility permissions for precise window targeting? → A: Yes, request Accessibility permissions to enable precise window/tab targeting for first-class supported apps

## Assumptions

- Claude Code hooks pass enough context (session ID, working directory, and parent process information) to identify the originating terminal application and window
- macOS UserNotifications framework is used for delivering notifications, providing standard macOS notification behavior including banner display, Notification Center history, and click handling
- The app can identify whether a session is running in Terminal.app, VS Code, or another application by inspecting the parent process tree of the Claude Code process
- Window focusing relies on macOS Accessibility permissions and platform APIs to activate and target the correct application window; the app requests Accessibility permissions on first use of window targeting
- The notification preference default is "enabled" and is stored using the same persistence mechanism as other app preferences
- VS Code is identified by its bundle identifier, and its window is matched by the project/working directory path
