import Foundation

@Observable
final class HookStatusProvider: StatusProvider {
    let sessionManager = SessionManager()
    private let socketListener = SocketListener()

    var currentStatus: StatusState {
        sessionManager.aggregateState
    }

    init() {
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
