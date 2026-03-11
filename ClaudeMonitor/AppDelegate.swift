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
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let parentPid = userInfo["parentPid"] as? Int ?? 0
        let parentApp = userInfo["parentApp"] as? String ?? ""
        let workingDir = userInfo["workingDir"] as? String ?? ""

        if parentPid > 0 || !parentApp.isEmpty {
            windowFocusManager.focusWindow(
                processId: pid_t(parentPid),
                bundleIdentifier: parentApp.isEmpty ? nil : parentApp,
                workingDirectory: workingDir
            )
        }
    }
}
