import Foundation

@Observable
final class SessionManager {
    private(set) var sessions: [String: SessionInfo] = [:]
    private var cleanupTimer: Timer?
    private let staleTimeout: TimeInterval = 300
    private let attentionTimeout: TimeInterval = 15
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
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.cleanupStaleSessions()
            self?.downgradeStaleAttention()
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

    /// Downgrades sessions stuck in `.attention` to `.waiting` when no new
    /// event has arrived within `attentionTimeout` seconds.  This handles the
    /// case where the user denies a permission request and the agent becomes
    /// idle without sending a follow-up state event.
    func downgradeStaleAttention() {
        let cutoff = Date().addingTimeInterval(-attentionTimeout)
        for (id, info) in sessions where info.state == .attention && info.lastEventTime <= cutoff {
            sessions[id] = SessionInfo(
                sessionId: info.sessionId,
                state: .waiting,
                workingDir: info.workingDir,
                lastEventTime: info.lastEventTime,
                parentPid: info.parentPid,
                parentApp: info.parentApp
            )
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}
