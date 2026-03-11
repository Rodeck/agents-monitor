import AppKit

enum StatusState: CaseIterable {
    case idle
    case waiting
    case running
    case attention

    var color: NSColor {
        switch self {
        case .idle: .systemGray
        case .waiting: .systemGreen
        case .running: .systemGreen
        case .attention: .systemOrange
        }
    }

    var isAnimated: Bool {
        switch self {
        case .idle, .waiting: false
        case .running, .attention: true
        }
    }
}
