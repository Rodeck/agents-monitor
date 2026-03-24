protocol StatusProvider: AnyObject {
    var currentStatus: StatusState { get }
}
