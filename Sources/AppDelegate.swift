import Foundation
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let host: String
    private let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the main window
        let contentView = ContentView(host: host, port: port)

        // Start with compact window size
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window?.center()
        window?.setFrameAutosaveName("AI Image Renamer")
        window?.title = "AI Image Renamer"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)

        // Set up notification observers for window resizing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(expandWindow),
            name: .expandWindow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(collapseWindow),
            name: .collapseWindow,
            object: nil
        )

        // Ensure the app stays running
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func expandWindow() {
        guard let window = window else { return }

        // Get current window position
        let currentFrame = window.frame
        let newWidth: CGFloat = 400
        let newHeight: CGFloat = 500

        // Calculate new origin to keep window centered
        let newX = currentFrame.origin.x - (newWidth - currentFrame.width) / 2
        let newY = currentFrame.origin.y - (newHeight - currentFrame.height) / 2

        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        })
    }

    @objc private func collapseWindow() {
        guard let window = window else { return }

        // Get current window position
        let currentFrame = window.frame
        let newWidth: CGFloat = 200
        let newHeight: CGFloat = 150

        // Calculate new origin to keep window centered
        let newX = currentFrame.origin.x + (currentFrame.width - newWidth) / 2
        let newY = currentFrame.origin.y + (currentFrame.height - newHeight) / 2

        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        })
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
