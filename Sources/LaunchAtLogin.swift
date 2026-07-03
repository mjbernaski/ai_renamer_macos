import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` (macOS 13+) so the app can register itself to
/// launch automatically at login. Registration only works when running from a
/// proper `.app` bundle (e.g. installed in /Applications) — when run as a bare
/// SPM binary via `swift run`, calls throw and are reported as unsupported.
enum LaunchAtLogin {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// True when we're running inside a real `.app` bundle and can register.
    static var isSupported: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    /// Enable or disable launch-at-login. Returns nil on success, or a
    /// human-readable error message on failure.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> String? {
        guard isSupported else {
            return "Launch at login requires running the installed app (drag it to /Applications)."
        }
        do {
            if enabled {
                // Registering when already enabled is a no-op that can throw; guard it.
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
