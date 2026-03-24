import Foundation
import Network

final class SocketListener {
    private var listener: NWListener?
    private let socketPath: String
    private let queue = DispatchQueue(label: "agents-monitor.socket")
    var onEvent: ((StateEvent) -> Void)?

    init(socketPath: String = "/tmp/agents-monitor.sock") {
        self.socketPath = socketPath
    }

    func start() {
        removeStaleSocket()

        let params = NWParameters()
        params.defaultProtocolStack.transportProtocol = NWProtocolTCP.Options()
        params.requiredLocalEndpoint = NWEndpoint.unix(path: socketPath)

        do {
            listener = try NWListener(using: params)
        } catch {
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.stateUpdateHandler = { _ in }

        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        removeStaleSocket()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveData(on: connection, accumulated: Data())
    }

    private func receiveData(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] content, _, isComplete, error in
            var data = accumulated
            if let content {
                data.append(content)
            }

            if isComplete || error != nil {
                self?.processMessage(data)
                connection.cancel()
                return
            }

            self?.receiveData(on: connection, accumulated: data)
        }
    }

    private func processMessage(_ data: Data) {
        guard !data.isEmpty,
              let event = try? JSONDecoder().decode(StateEvent.self, from: data),
              event.statusState != nil else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(event)
        }
    }

    private func removeStaleSocket() {
        try? FileManager.default.removeItem(atPath: socketPath)
    }

    deinit {
        stop()
    }
}
