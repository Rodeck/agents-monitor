import AppKit
import ApplicationServices

final class WindowFocusManager {
    private var hasPromptedAccessibility = false

    func focusWindow(processId: pid_t, bundleIdentifier: String?, workingDirectory: String) {
        let dirName = (workingDirectory as NSString).lastPathComponent

        let work = { [self] in
            if AXIsProcessTrusted() && processId > 0 {
                if raiseMatchingWindow(pid: processId, directoryName: dirName) {
                    activateApp(pid: processId)
                    return
                }
            } else if !hasPromptedAccessibility && processId > 0 {
                promptAccessibilityIfNeeded()
            }

            if let bundleId = bundleIdentifier, !bundleId.isEmpty {
                activateAppByBundleId(bundleId)
            } else if processId > 0 {
                activateApp(pid: processId)
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
        guard let bundleURL = app.bundleURL else {
            app.activate()
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: config)
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
