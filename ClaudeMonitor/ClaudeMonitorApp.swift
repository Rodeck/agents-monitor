import SwiftUI

@main
struct ClaudeMonitorApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            Text("Claude Monitor")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(nsImage: appState.currentIcon)
        }
        .menuBarExtraStyle(.menu)
    }
}

@Observable
final class AppState {
    private var statusProvider = MockStatusProvider()
    private var flashVisible = true
    private var flashTimer: Timer?

    var currentIcon: NSImage {
        let status = statusProvider.currentStatus
        if status.isAnimated && !flashVisible {
            return StatusIconRenderer.makeIcon(color: .clear)
        }
        return StatusIconRenderer.makeIcon(color: status.color)
    }

    init() {
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.statusProvider.currentStatus.isAnimated {
                self.flashVisible.toggle()
            } else {
                self.flashVisible = true
            }
        }
    }

    deinit {
        flashTimer?.invalidate()
    }
}
