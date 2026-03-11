import Foundation

@Observable
final class SessionManager {
    private(set) var sessions: [String: SessionInfo] = [:]
    private var cleanupTimer: Timer?
    private let staleTimeout: TimeInterval = 300

    var aggregateState: StatusState {
        if sessions.isEmpty { return .idle }
        if sessions.values.contains(where: { $0.state == .attention }) { return .attention }
        if sessions.values.contains(where: { $0.state == .running }) { return .running }
        return .idle
    }

    var activeSessionCount: Int {
        sessions.count
    }

    func handleEvent(_ event: StateEvent) {
        guard let state = event.statusState else { return }

        if state == .idle {
            sessions.removeValue(forKey: event.sid)
        } else {
            sessions[event.sid] = SessionInfo(
                sessionId: event.sid,
                state: state,
                workingDir: event.cwd,
                lastEventTime: Date()
            )
        }
    }

    func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.cleanupStaleSessions()
        }
    }

    func cleanupStaleSessions() {
        let cutoff = Date().addingTimeInterval(-staleTimeout)
        sessions = sessions.filter { $0.value.lastEventTime > cutoff }
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}
