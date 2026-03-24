import AppKit
import ApplicationServices

final class WindowFocusManager {
    private var hasPromptedAccessibility = false

    func focusWindow(processId: pid_t, bundleIdentifier: String?, workingDirectory: String) {
        let dirName = (workingDirectory as NSString).lastPathComponent

        let work = { [self] in
            NSLog("[AgentsMonitor] focusWindow — pid=%d bundle=%@ dir=%@ axTrusted=%d",
                  processId, bundleIdentifier ?? "nil", dirName, AXIsProcessTrusted() ? 1 : 0)

            // Try Accessibility-based window targeting to raise the correct tab/window
            if AXIsProcessTrusted() && processId > 0 {
                let raised = raiseMatchingWindow(pid: processId, directoryName: dirName)
                NSLog("[AgentsMonitor] raiseMatchingWindow=%d", raised ? 1 : 0)
            } else if !hasPromptedAccessibility && processId > 0 {
                promptAccessibilityIfNeeded()
            }

            // `open -b` is the most reliable way for an LSUIElement app to
            // bring another application to the foreground — use it first.
            if let bundleId = bundleIdentifier, !bundleId.isEmpty {
                NSLog("[AgentsMonitor] opening via CLI: %@", bundleId)
                openAppViaCLI(bundleId: bundleId)
            } else if processId > 0 {
                NSLog("[AgentsMonitor] activating by PID (no bundleId)")
                activateApp(pid: processId)
            } else {
                NSLog("[AgentsMonitor] no bundleId and no PID — cannot focus")
            }
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }

    // MARK: - App Activation

    private func activateApp(pid: pid_t) {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        activateViaWorkspace(app: app)
    }

    private func activateAppByBundleId(_ bundleId: String) {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first else { return }
        activateViaWorkspace(app: app)
    }

    private func activateViaWorkspace(app: NSRunningApplication) {
        app.activate()
    }

    /// Reliable fallback: `open -b` always brings the app to the foreground,
    /// even when called from an LSUIElement (background) agent app.
    private func openAppViaCLI(bundleId: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-b", bundleId]
        try? task.run()
    }

    // MARK: - Accessibility Window Targeting

    private func raiseMatchingWindow(pid: pid_t, directoryName: String) -> Bool {
        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return false
        }

        for window in windows {
            var titleRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                  let title = titleRef as? String else {
                continue
            }

            if title.contains(directoryName) {
                AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                return true
            }
        }

        return false
    }

    private func promptAccessibilityIfNeeded() {
        hasPromptedAccessibility = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
