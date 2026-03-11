# Research: Status Notifications with Window Focus

**Feature**: 003-status-notifications
**Date**: 2026-03-11

## R1: macOS Notification Delivery (UNUserNotificationCenter)

**Decision**: Use `UNUserNotificationCenter` for all notification functionality.

**Rationale**: This is the modern Apple-recommended API for macOS notifications (replacing deprecated `NSUserNotification`). It provides permission management, notification content, sound, and click-response handling all in one framework. Available on macOS 10.14+ (our target is 14+).

**Key APIs**:
- `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])` — request permission
- `UNMutableNotificationContent` — set title, body, sound, userInfo
- `UNNotificationRequest` — schedule notification with unique identifier
- `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` — handle click

**Alternatives considered**:
- `NSUserNotification` — deprecated since macOS 10.14, removed in macOS 11
- Third-party notification libraries — unnecessary overhead for standard notifications

**Gotchas**:
- The delegate must be set via `@NSApplicationDelegateAdaptor(AppDelegate.self)` in the SwiftUI App struct. The AppDelegate must conform to `UNUserNotificationCenterDelegate` and set itself as delegate in `applicationDidFinishLaunching`. If set too late, the `didReceive` callback is silently never called.
- Menu bar apps (MenuBarExtra) are effectively always "foreground" from the notification perspective, so `willPresent` delegate must return `[.banner, .sound]` or notifications are silently swallowed.
- Notifications are delivered even when the app is in the foreground (with `userNotificationCenter(_:willPresent:)` delegate method returning `.banner, .sound`)
- No entitlement needed for non-sandboxed apps

## R2: Window Focusing — App Activation vs Window Targeting

**Decision**: Two-tier approach:
1. **App activation** (no special permissions): `NSRunningApplication(processIdentifier: pid)?.activate()` or `NSWorkspace.shared.open(URL(fileURLWithPath: bundlePath))`
2. **Window targeting** (Accessibility permissions): `AXUIElement` API for precise window/tab selection

**Rationale**: App activation is sufficient for most cases (macOS brings the most recent window forward). Window targeting via Accessibility is needed when the app has multiple windows and we need to focus a specific one (e.g., VS Code with multiple project windows).

**Key APIs**:
- `NSRunningApplication(processIdentifier: pid)?.activate(options: .activateIgnoringOtherApps)` — activate app
- `AXIsProcessTrusted()` — check if Accessibility is granted
- `AXUIElementCreateApplication(pid)` — create AX reference for a process
- `AXUIElementCopyAttributeValue(element, kAXWindowsAttribute, &windows)` — get windows
- `AXUIElementCopyAttributeValue(window, kAXTitleAttribute, &title)` — get window title
- `AXUIElementPerformAction(window, kAXRaiseAction)` — raise specific window

**Alternatives considered**:
- AppleScript (`tell application "Terminal" to activate`) — works but slower, requires `osascript` subprocess
- `NSWorkspace.shared.open` — only opens/activates apps, no window targeting

## R3: Identifying Parent Terminal Application

**Decision**: Extend the hook script to capture the parent process information and send it as part of the event payload.

**Rationale**: The hook script runs as a child of Claude Code, which runs as a child of the terminal app. Walking up the process tree in the hook script (using `ps`) is simpler and more reliable than trying to reconstruct the process tree from the app side.

**Implementation in hook script**:
```bash
# Get Claude Code's parent PID (the terminal app)
TERMINAL_PID=$(ps -o ppid= -p $PPID | tr -d ' ')
# Get the app bundle identifier
APP_BUNDLE=$(lsappinfo info -only bundleid $(lsappinfo find pid=$TERMINAL_PID) 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
# Fallback to process name
[ -z "$APP_BUNDLE" ] && APP_BUNDLE=$(ps -o comm= -p $TERMINAL_PID 2>/dev/null)
```

**Alternatives considered**:
- App-side process tree inspection (using `sysctl` or `/proc`) — more complex, requires the app to know the Claude Code PID
- Requiring users to configure which terminal they use — poor UX, unnecessary
- Using `NSWorkspace.shared.frontmostApplication` at notification time — unreliable (user may have switched apps)

## R4: App-Specific Window Matching Strategies

**Decision**: Use different strategies per first-class app:

| App | Window Match Strategy |
|-----|----------------------|
| Terminal.app | Match by window title containing the working directory name, or AX window attributes |
| VS Code | Match by window title containing the project directory name (VS Code titles include project name) |
| iTerm2 | Match by window/tab title containing the working directory or session name |

**Rationale**: Each app formats its window titles differently, but all typically include the working directory or project name. Title matching is the most reliable cross-app approach without needing app-specific scripting bridges.

**Fallback chain**:
1. Try Accessibility window-title matching → raise matched window
2. If no match or no Accessibility → activate app (brings most recent window)
3. If process not running → activate app by bundle ID (may launch it)

## R5: Notification Coalescing

**Decision**: Track last notification timestamp per session ID in a dictionary. Skip sending if within 5-second window.

**Rationale**: Simple in-memory dictionary is sufficient. No need for timers or debouncing — just a timestamp check before sending.

**Implementation**:
- `lastNotificationTime: [String: Date]` dictionary in NotificationManager
- Before sending: check if `Date().timeIntervalSince(lastTime) < 5.0`
- Clean up entries when sessions are removed

## R6: Preference Persistence

**Decision**: Use `UserDefaults.standard` with key `"notificationsEnabled"`, defaulting to `true`.

**Rationale**: UserDefaults is the standard macOS mechanism for simple app preferences. A single boolean doesn't warrant CoreData, a plist file, or any other storage mechanism.

**Key pattern**:
- Register default: `UserDefaults.standard.register(defaults: ["notificationsEnabled": true])`
- Read: `UserDefaults.standard.bool(forKey: "notificationsEnabled")`
- Write: `UserDefaults.standard.set(value, forKey: "notificationsEnabled")`
- SwiftUI binding: `@AppStorage("notificationsEnabled") var notificationsEnabled = true`

## R7: Accessibility Permission Prompt

**Decision**: Check `AXIsProcessTrusted()` before attempting window targeting. If not trusted, prompt user with `AXIsProcessTrustedWithOptions` which shows the system Security & Privacy dialog.

**Rationale**: Standard macOS pattern. The prompt is system-managed and only appears once. After granting, no app restart is needed (the API call succeeds immediately).

**Key APIs**:
- `AXIsProcessTrusted() -> Bool` — check current status
- `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)` — check and prompt if not trusted

**Timing**: Check on first notification click that requires window targeting, not on app launch. Avoids prompting users who may not need it.

**Gotcha**: After the user grants Accessibility permission in System Settings, the app may need to be restarted for `AXIsProcessTrusted()` to return `true`. This is a known macOS behavior. The app should handle this gracefully by falling back to app-level activation if Accessibility is not yet effective.
