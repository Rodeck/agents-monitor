import Foundation

struct StateEvent: Codable {
    let sid: String
    let state: String
    let cwd: String
    let ts: Int
    let ppid: Int?
    let app: String?

    var statusState: StatusState? {
        switch state {
        case "running": .running
        case "waiting": .waiting
        case "attention": .attention
        case "idle": .idle
        default: nil
        }
    }
}
