import Foundation

@Observable
final class MockStatusProvider: StatusProvider {
    private(set) var currentStatus: StatusState = .idle
    private var timer: Timer?

    private static let cycle: [StatusState] = [.idle, .running, .attention]
    private var cycleIndex = 0

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.cycleIndex = (self.cycleIndex + 1) % Self.cycle.count
            self.currentStatus = Self.cycle[self.cycleIndex]
        }
    }

    deinit {
        timer?.invalidate()
    }
}
