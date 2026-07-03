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
    
    @Option(name: .long, help: "LM Studio host (overrides config.json)")
    var host: String?

    @Option(name: .shortAndLong, help: "LM Studio port (overrides config.json)")
    var port: Int?
    
    @Flag(help: "Show what would be renamed without actually renaming")
    var dryRun: Bool = false
    
    @Flag(help: "Auto-approve all suggestions (CLI mode only)")
    var autoApprove: Bool = false
    
    @Argument(help: "Files to process (CLI mode only)")
    var files: [String] = []


    func run() throws {
        // Start from config.json; CLI flags override host/port when provided.
        var config = AppConfig.load()
        if let host { config.host = host }
        if let port { config.port = port }

        if cli {
            runCLISync(config: config)
        } else {
            // Force GUI mode when no CLI flag is provided
            try runGUI(config: config)
        }
    }

    private func runCLISync(config: AppConfig) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                let processor = FileProcessor(config: config)
                try await processor.processFiles(files, dryRun: dryRun, autoApprove: autoApprove)
            } catch {
                print("Error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    private func runGUI(config: AppConfig) throws {
        let app = NSApplication.shared
        let delegate = AppDelegate(config: config)
        app.delegate = delegate
        app.run()
    }
}

// Entry point
if CommandLine.arguments.count == 1 {
    // No arguments provided, launch GUI directly using config.json.
    let app = NSApplication.shared
    let delegate = AppDelegate(config: AppConfig.load())
    app.delegate = delegate
    app.run()
} else {
    // Arguments provided, use ArgumentParser
    AIImageRenamer.main()
}
