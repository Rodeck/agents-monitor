import Foundation
import UserNotifications

final class NotificationManager {
    private var lastNotificationTime: [String: Date] = [:]
    private let coalescingInterval: TimeInterval = 5.0

    init() {
        UserDefaults.standard.register(defaults: ["notificationsEnabled": true])
    }

    func notifyIfNeeded(session: SessionInfo) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        guard shouldSendNotification(for: session.sessionId) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Agent needs attention"
        content.body = (session.workingDir as NSString).lastPathComponent
        content.sound = .default
        content.categoryIdentifier = "SESSION_ATTENTION"
        content.userInfo = [
            "sessionId": session.sessionId,
            "workingDir": session.workingDir,
            "parentPid": session.parentPid ?? 0,
            "parentApp": session.parentApp ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: "attention-\(session.sessionId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        lastNotificationTime[session.sessionId] = Date()
    }

    func cleanupSession(_ sessionId: String) {
        lastNotificationTime.removeValue(forKey: sessionId)
    }

    private func shouldSendNotification(for sessionId: String) -> Bool {
        guard let lastTime = lastNotificationTime[sessionId] else { return true }
        return Date().timeIntervalSince(lastTime) >= coalescingInterval
    }
}
