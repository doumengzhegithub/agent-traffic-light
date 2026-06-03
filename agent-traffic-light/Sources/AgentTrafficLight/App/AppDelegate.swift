import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSPanel?
    private var viewModel: TrafficLightViewModel?
    private let terminalWindowTracker = TerminalWindowTracker()
    private var trackingTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let monitor = AgentStatusMonitor(providers: [CodexProvider()])
        let viewModel = TrafficLightViewModel(monitor: monitor)
        self.viewModel = viewModel

        let window = makeWindow(viewModel: viewModel)
        self.window = window
        viewModel.start()
        startWindowTracking()
    }

    func applicationWillTerminate(_ notification: Notification) {
        trackingTimer?.invalidate()
        viewModel?.stop()
    }

    private func makeWindow(viewModel: TrafficLightViewModel) -> NSPanel {
        let contentView = TrafficLightView(viewModel: viewModel)
        let hostingView = ContextMenuHostingView(rootView: contentView)
        hostingView.contextMenu = makeMenu()

        let panel = NSPanel(
            contentRect: NSRect(x: 120, y: 640, width: 52, height: 124),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.transient, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.title = "Agent Traffic Light"

        return panel
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Refresh",
            action: #selector(refresh),
            keyEquivalent: "r"
        ))
        menu.addItem(NSMenuItem(
            title: "Copy Status",
            action: #selector(copyStatus),
            keyEquivalent: "c"
        ))
        menu.addItem(NSMenuItem(
            title: "Reposition",
            action: #selector(reposition),
            keyEquivalent: "0"
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }

        return menu
    }

    @objc private func refresh() {
        Task {
            await viewModel?.refresh()
        }
    }

    @objc private func copyStatus() {
        guard let viewModel else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.debugStatusText, forType: .string)
    }

    @objc private func reposition() {
        updateWindowPlacement()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func startWindowTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateWindowPlacement()
            }
        }
        updateWindowPlacement()
    }

    private func updateWindowPlacement() {
        Task { [weak self] in
            guard let self else {
                return
            }

            let placement = await terminalWindowTracker.placement()

            await MainActor.run {
                guard let window = self.window else {
                    return
                }

                guard placement.shouldShow, let frame = placement.frame else {
                    window.orderOut(nil)
                    return
                }

                window.setFrame(frame, display: true)
                window.orderFrontRegardless()
            }
        }
    }
}

private final class ContextMenuHostingView<Content: View>: NSHostingView<Content> {
    var contextMenu: NSMenu?

    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu else {
            super.rightMouseDown(with: event)
            return
        }

        NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
    }
}
