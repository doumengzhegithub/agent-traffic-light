import AppKit
import CoreGraphics

struct CodexAttentionProbe: Sendable {
    @MainActor
    func needsAttention() -> Bool {
        guard
            let activeApplication = Self.frontmostTerminalApplication(),
            let title = Self.frontWindowTitle(for: activeApplication.processIdentifier)
        else {
            return false
        }

        return Self.isAttentionTitle(title)
    }

    @MainActor
    func isTerminalFrontmost() -> Bool {
        Self.frontmostTerminalApplication() != nil
    }

    static func isAttentionTitle(_ title: String) -> Bool {
        let lowercased = title.lowercased()

        return lowercased.contains("action required")
            || lowercased.contains("[!]")
            || lowercased.contains("approval")
            || lowercased.contains("confirm")
            || lowercased.contains("permission")
    }

    private static func isTerminalApplication(_ application: NSRunningApplication) -> Bool {
        let bundleIdentifier = application.bundleIdentifier?.lowercased() ?? ""
        let localizedName = application.localizedName?.lowercased() ?? ""

        return bundleIdentifier == "com.apple.terminal"
            || bundleIdentifier == "com.googlecode.iterm2"
            || bundleIdentifier.contains("ghostty")
            || bundleIdentifier.contains("warp")
            || localizedName == "terminal"
            || localizedName == "iterm2"
            || localizedName.contains("ghostty")
            || localizedName.contains("warp")
    }

    @MainActor
    private static func frontmostTerminalApplication() -> NSRunningApplication? {
        guard
            let activeApplication = NSWorkspace.shared.frontmostApplication,
            isTerminalApplication(activeApplication)
        else {
            return nil
        }

        return activeApplication
    }

    private static func frontWindowTitle(for processIdentifier: pid_t) -> String? {
        guard
            let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return nil
        }

        for window in windows {
            guard
                window[kCGWindowOwnerPID as String] as? pid_t == processIdentifier,
                window[kCGWindowLayer as String] as? Int == 0
            else {
                continue
            }

            return window[kCGWindowName as String] as? String
        }

        return nil
    }
}
