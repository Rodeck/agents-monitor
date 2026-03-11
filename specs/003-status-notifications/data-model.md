# Data Model: Status Notifications with Window Focus

**Feature**: 003-status-notifications
**Date**: 2026-03-11

## Entities

### StateEvent (Extended)

Extends the existing `StateEvent` struct with parent application context.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| sid | String | Yes | Session identifier from Claude Code |
| state | String | Yes | One of: "running", "attention", "idle" |
| cwd | String | Yes | Working directory path |
| ts | Int | Yes | Unix timestamp |
| ppid | Int | No | Process ID of the terminal application hosting Claude Code |
| app | String | No | Bundle identifier or process name of the terminal application |

**Notes**:
- `ppid` and `app` are optional for backward compatibility with existing hook scripts
- If `ppid`/`app` are missing, window focusing falls back to best-effort app activation
- `app` values: "com.apple.Terminal", "com.microsoft.VSCode", "com.googlecode.iterm2", or process name

### SessionInfo (Extended)

Extends the existing `SessionInfo` struct with parent application context.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| sessionId | String | Yes | Unique session identifier |
| state | StatusState | Yes | Current session state |
| workingDir | String | Yes | Project working directory |
| lastEventTime | Date | Yes | Timestamp of last received event |
| parentPid | Int? | No | Terminal application process ID |
| parentApp | String? | No | Terminal application identifier |

### WindowReference (New)

Encapsulates the information needed to locate and focus the correct application window.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| processId | Int | Yes | Process ID of the terminal application |
| bundleIdentifier | String? | No | macOS bundle identifier (e.g., "com.apple.Terminal") |
| workingDirectory | String | Yes | Project path for matching VS Code windows |

### NotificationPreference (New)

Persistent user setting for notification behavior.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| notificationsEnabled | Bool | true | Whether desktop notifications are shown for attention states |

**Storage**: UserDefaults with key `"notificationsEnabled"`

## State Transitions

### Notification Trigger Flow

```
Session state change received
    ↓
Is new state == .attention?
    ├─ No → No notification (exit)
    └─ Yes ↓
        Is notificationsEnabled?
        ├─ No → No notification (exit)
        └─ Yes ↓
            Was notification sent for this session in last 5 seconds?
            ├─ Yes → Coalesce / skip (exit)
            └─ No ↓
                Send UNNotification with session context
                Record timestamp for coalescing
```

### Notification Click Flow

```
User clicks notification
    ↓
Extract session ID from notification userInfo
    ↓
Look up SessionInfo (or cached WindowReference)
    ↓
Is parentApp a first-class supported app?
    ├─ Yes → Use app-specific window targeting (Accessibility API)
    └─ No → Use generic app activation (NSRunningApplication.activate)
        ↓
    Is process still running?
    ├─ Yes → Activate app and target window
    └─ No → Best-effort: activate app by bundle ID (no specific window)
```

## Relationships

```
HookStatusProvider
    ├── SessionManager
    │       └── [String: SessionInfo]  (sessions dictionary)
    └── SocketListener
            └── onEvent → StateEvent

NotificationManager (NEW)
    ├── UNUserNotificationCenter (system)
    ├── SessionManager (read sessions for context)
    ├── WindowFocusManager (delegate click actions)
    └── lastNotificationTime: [String: Date] (coalescing tracker)

WindowFocusManager (NEW)
    ├── NSRunningApplication (app activation)
    └── AXUIElement (window targeting, needs Accessibility)
```
