import Foundation

@Observable
final class HookStatusProvider: StatusProvider {
    let sessionManager = SessionManager()
    let notificationManager = NotificationManager()
    private let socketListener = SocketListener()

    var currentStatus: StatusState {
        sessionManager.aggregateState
    }

    init() {
        sessionManager.onAttention = { [weak self] session in
            self?.notificationManager.notifyIfNeeded(session: session)
        }
        sessionManager.onSessionRemoved = { [weak self] sessionId in
            self?.notificationManager.cleanupSession(sessionId)
        }
        socketListener.onEvent = { [weak self] event in
            self?.sessionManager.handleEvent(event)
        }
        socketListener.start()
        sessionManager.startCleanupTimer()
    }

    deinit {
        socketListener.stop()
    }
}
