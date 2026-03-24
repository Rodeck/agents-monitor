import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var windowFocusManager = WindowFocusManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let parentPid = userInfo["parentPid"] as? Int ?? 0
        let parentApp = userInfo["parentApp"] as? String ?? ""
        let workingDir = userInfo["workingDir"] as? String ?? ""

        NSLog("[ClaudeMonitor] Notification clicked — pid=%d app=%@ cwd=%@", parentPid, parentApp, workingDir)

        // Use the detected parent app, or fall back to known terminal apps
        let bundleId = !parentApp.isEmpty ? parentApp : detectTerminalBundleId()

        NSLog("[ClaudeMonitor] Resolved bundleId=%@", bundleId ?? "nil")

        windowFocusManager.focusWindow(
            processId: pid_t(parentPid),
            bundleIdentifier: bundleId,
            workingDirectory: workingDir
        )

        completionHandler()
    }

    /// Try to find a running terminal app that likely hosts Claude Code.
    private func detectTerminalBundleId() -> String? {
        let knownTerminals = [
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",  // Cursor
            "dev.warp.Warp-Stable",
            "com.mitchellh.ghostty",
            "com.googlecode.iterm2",
            "com.apple.Terminal"
        ]
        for bundleId in knownTerminals {
            if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).isEmpty {
                return bundleId
            }
        }
        return nil
    }
}
