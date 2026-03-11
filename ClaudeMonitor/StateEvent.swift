import Foundation

struct StateEvent: Codable {
    let sid: String
    let state: String
    let cwd: String
    let ts: Int

    var statusState: StatusState? {
        switch state {
        case "running": .running
        case "attention": .attention
        case "idle": .idle
        default: nil
        }
    }
}
