import AppKit
import CoreGraphics

struct TerminalWindowPlacement: Equatable {
    let shouldShow: Bool
    let frame: NSRect?
}

struct TerminalWindowTracker {
    private let dotWindowSize = NSSize(width: 52, height: 124)
    private let outsideGap: CGFloat = 8
    private let topInset: CGFloat = 0

    func placement() async -> TerminalWindowPlacement {
        guard
            let activeApplication = await MainActor.run(body: {
                NSWorkspace.shared.frontmostApplication
            }),
            Self.isTerminalApplication(activeApplication)
        else {
            return TerminalWindowPlacement(shouldShow: false, frame: nil)
        }

        let frame = Self.frontWindowBounds(for: activeApplication.processIdentifier)
            .map(frameForTrafficLight)
            ?? fallbackFrame()

        return TerminalWindowPlacement(shouldShow: true, frame: frame)
    }

    private func frameForTrafficLight(in windowBounds: CGRect) -> NSRect {
        let topLeftOrigin = CGPoint(
            x: windowBounds.minX - dotWindowSize.width - outsideGap,
            y: windowBounds.minY + topInset
        )
        let bottomLeftOrigin = convertTopLeftScreenPointToAppKit(
            topLeftOrigin,
            size: dotWindowSize
        )

        return clampToVisibleScreen(NSRect(origin: bottomLeftOrigin, size: dotWindowSize))
    }

    private func convertTopLeftScreenPointToAppKit(
        _ point: CGPoint,
        size: NSSize
    ) -> NSPoint {
        let globalMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? 0
        return NSPoint(
            x: point.x,
            y: globalMaxY - point.y - size.height
        )
    }

    private func fallbackFrame() -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        return NSRect(
            x: screenFrame.minX + outsideGap,
            y: screenFrame.maxY - outsideGap - dotWindowSize.height,
            width: dotWindowSize.width,
            height: dotWindowSize.height
        )
    }

    private func clampToVisibleScreen(_ frame: NSRect) -> NSRect {
        guard let screenFrame = NSScreen.screens
            .map(\.visibleFrame)
            .first(where: { $0.intersects(frame) || $0.contains(frame.origin) })
            ?? NSScreen.main?.visibleFrame
        else {
            return frame
        }

        let x = min(
            max(frame.origin.x, screenFrame.minX + outsideGap),
            screenFrame.maxX - frame.width - outsideGap
        )
        let y = min(
            max(frame.origin.y, screenFrame.minY + outsideGap),
            screenFrame.maxY - frame.height - outsideGap
        )

        return NSRect(origin: NSPoint(x: x, y: y), size: frame.size)
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

    private static func frontWindowBounds(for processIdentifier: pid_t) -> CGRect? {
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
                window[kCGWindowLayer as String] as? Int == 0,
                let boundsDictionary = window[kCGWindowBounds as String] as? [String: Any],
                let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary),
                bounds.width > 80,
                bounds.height > 80
            else {
                continue
            }

            return bounds
        }

        return nil
    }
}
