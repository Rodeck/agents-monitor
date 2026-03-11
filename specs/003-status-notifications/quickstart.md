# Quickstart: Status Notifications with Window Focus

**Feature**: 003-status-notifications
**Date**: 2026-03-11

## Prerequisites

- macOS 14+ (Sonoma)
- Swift 5.9+
- Existing Claude Monitor app (features 001 + 002 implemented)
- Claude Code with hooks configured

## New Files to Create

| File | Purpose |
|------|---------|
| `ClaudeMonitor/NotificationManager.swift` | UNUserNotificationCenter wrapper: permissions, sending, click handling |
| `ClaudeMonitor/WindowFocusManager.swift` | Window targeting for Terminal.app, VS Code, iTerm2 using Accessibility API |

## Existing Files to Modify

| File | Changes |
|------|---------|
| `ClaudeMonitor/StateEvent.swift` | Add optional `ppid: Int?` and `app: String?` fields |
| `ClaudeMonitor/SessionInfo.swift` | Add optional `parentPid: Int?` and `parentApp: String?` fields |
| `ClaudeMonitor/SessionManager.swift` | Pass new fields through `handleEvent()`, expose attention transitions |
| `ClaudeMonitor/HookStatusProvider.swift` | Wire NotificationManager to session attention events |
| `ClaudeMonitor/ClaudeMonitorApp.swift` | Add notification toggle to menu, initialize NotificationManager |
| `ClaudeMonitor/Resources/Info.plist` | No changes needed (not sandboxed, notifications don't need entitlement) |
| `scripts/claude-monitor-hook.sh` | Capture parent PID and app bundle identifier |

## Build & Test

```bash
# Build
swift build -c release

# Bundle
scripts/bundle-app.sh

# Run
open build/ClaudeMonitor.app
```

## Testing Checklist

1. **Notification permission**: On first attention event, macOS prompts for notification permission
2. **Notification delivery**: Trigger attention state → notification banner appears within 2 seconds
3. **Click-to-focus Terminal**: Click notification → Terminal.app activates with correct window
4. **Click-to-focus VS Code**: Click notification → VS Code activates with correct project window
5. **Click-to-focus iTerm2**: Click notification → iTerm2 activates with correct window
6. **Coalescing**: Rapid attention events for same session → only one notification per 5 seconds
7. **Toggle**: Disable notifications in menu → no notifications; re-enable → notifications resume
8. **Persistence**: Quit and relaunch app → notification toggle remembers its state
9. **Permission denied**: Deny notification permissions → app continues working, menu bar icon updates normally
10. **Accessibility**: Grant Accessibility permission → precise window targeting works
