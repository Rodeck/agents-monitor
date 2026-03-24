import Foundation

struct SessionInfo {
    let sessionId: String
    var state: StatusState
    var workingDir: String
    var lastEventTime: Date
    var parentPid: Int?
    var parentApp: String?
}
