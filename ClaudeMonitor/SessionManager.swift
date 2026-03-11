import Foundation

@Observable
final class SessionManager {
    private(set) var sessions: [String: SessionInfo] = [:]
    private var cleanupTimer: Timer?
    private let staleTimeout: TimeInterval = 300
    var onAttention: ((SessionInfo) -> Void)?
    var onSessionRemoved: ((String) -> Void)?

    var aggregateState: StatusState {
        if sessions.isEmpty { return .idle }
        if sessions.values.contains(where: { $0.state == .attention }) { return .attention }
        if sessions.values.contains(where: { $0.state == .running }) { return .running }
        if sessions.values.contains(where: { $0.state == .waiting }) { return .waiting }
        return .idle
    }

    var activeSessionCount: Int {
        sessions.count
    }

    func handleEvent(_ event: StateEvent) {
        guard let state = event.statusState else { return }

        let previousState = sessions[event.sid]?.state

        if state == .idle {
            sessions.removeValue(forKey: event.sid)
            onSessionRemoved?(event.sid)
        } else {
            sessions[event.sid] = SessionInfo(
                sessionId: event.sid,
                state: state,
                workingDir: event.cwd,
                lastEventTime: Date(),
                parentPid: event.ppid,
                parentApp: event.app
            )
        }

        if state == .attention && previousState != .attention,
           let session = sessions[event.sid] {
            onAttention?(session)
        }
    }

    func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.cleanupStaleSessions()
        }
    }

    func cleanupStaleSessions() {
        let cutoff = Date().addingTimeInterval(-staleTimeout)
        let staleIds = sessions.filter { $0.value.lastEventTime <= cutoff }.map(\.key)
        for id in staleIds {
            sessions.removeValue(forKey: id)
            onSessionRemoved?(id)
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}
