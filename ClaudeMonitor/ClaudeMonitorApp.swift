import SwiftUI

@main
struct ClaudeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some Scene {
        MenuBarExtra {
            Text("Claude Monitor")
            Divider()
            let count = appState.activeSessionCount
            if count > 0 {
                Text("\(count) session\(count == 1 ? "" : "s") active")
                    .foregroundStyle(.secondary)
            } else {
                Text("No active sessions")
                    .foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Notifications", isOn: $notificationsEnabled)
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
    private var statusProvider = HookStatusProvider()
    private var flashVisible = true
    private var flashTimer: Timer?

    var activeSessionCount: Int {
        statusProvider.sessionManager.activeSessionCount
    }

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
