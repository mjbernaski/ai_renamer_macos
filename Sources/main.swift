import Foundation
import ArgumentParser
import AppKit

struct AIImageRenamer: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ai-renamer",
        abstract: "AI-powered image and PDF renamer for macOS",
        usage: "ai-renamer [--cli <files>...] [options]",
        discussion: """
        This tool uses LM Studio's local API to generate intelligent filename suggestions
        based on image content or PDF text. It provides both GUI and CLI interfaces.
        
        By default, launches the GUI interface. Use --cli flag for command-line mode.
        """
    )
    
    @Flag(name: .shortAndLong, help: "Run in command-line mode (no GUI)")
    var cli: Bool = false
    
    @Option(name: .long, help: "LM Studio host")
    var host: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "LM Studio port")
    var port: Int = 1234
    
    @Flag(help: "Show what would be renamed without actually renaming")
    var dryRun: Bool = false
    
    @Flag(help: "Auto-approve all suggestions (CLI mode only)")
    var autoApprove: Bool = false
    
    @Argument(help: "Files to process (CLI mode only)")
    var files: [String] = []


    func run() throws {
        if cli {
            runCLISync()
        } else {
            // Force GUI mode when no CLI flag is provided
            try runGUI()
        }
    }
    
    private func runCLISync() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                let processor = FileProcessor(host: host, port: port)
                try await processor.processFiles(files, dryRun: dryRun, autoApprove: autoApprove)
            } catch {
                print("Error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    private func runCLI() async throws {
        let processor = FileProcessor(host: host, port: port)
        try await processor.processFiles(files, dryRun: dryRun, autoApprove: autoApprove)
    }
    
    private func runGUI() throws {
        let app = NSApplication.shared
        let delegate = AppDelegate(host: host, port: port)
        app.delegate = delegate
        app.run()
    }
}

// Entry point
if CommandLine.arguments.count == 1 {
    // No arguments provided, launch GUI directly
    let app = NSApplication.shared
    let delegate = AppDelegate(host: "127.0.0.1", port: 1234)
    app.delegate = delegate
    app.run()
} else {
    // Arguments provided, use ArgumentParser
    AIImageRenamer.main()
}
