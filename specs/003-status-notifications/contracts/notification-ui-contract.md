# Notification UI Contract

**Feature**: 003-status-notifications
**Date**: 2026-03-11

## macOS Notification Format

### Notification Content

| Field | Value | Example |
|-------|-------|---------|
| Title | "Claude needs attention" | "Claude needs attention" |
| Body | Project directory name (last path component of `cwd`) | "my-project" |
| Sound | Default system notification sound | UNNotificationSound.default |
| Category | "SESSION_ATTENTION" | Used for action handling |

### Notification userInfo Payload

Stored in the notification for retrieval when clicked:

```json
{
  "sessionId": "<string: session ID>",
  "workingDir": "<string: full working directory path>",
  "parentPid": "<integer: terminal process ID, or 0 if unknown>",
  "parentApp": "<string: bundle identifier, or empty if unknown>"
}
```

### Menu Bar Dropdown

New items added to the existing dropdown menu:

```
Claude Monitor
─────────────
2 sessions active
─────────────
✓ Notifications          ← Toggle (checkmark when enabled)
─────────────
Quit
```

### Notification Behavior

- **Trigger**: Only on transition to `attention` state
- **Coalescing**: Max one notification per session per 5-second window
- **Click action**: Focus originating terminal/editor window
- **Dismiss**: Standard macOS dismiss behavior (swipe, click X)
- **Permission denied**: No notifications shown; menu bar icon continues to work; toggle still visible but shows system notification settings on click when denied
