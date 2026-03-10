import AppKit

enum StatusState: CaseIterable {
    case idle
    case running
    case attention

    var color: NSColor {
        switch self {
        case .idle: .systemGray
        case .running: .systemGreen
        case .attention: .systemOrange
        }
    }

    var isAnimated: Bool {
        switch self {
        case .idle: false
        case .running, .attention: true
        }
    }
}
