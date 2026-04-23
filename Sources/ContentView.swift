import SwiftUI
import UniformTypeIdentifiers

@available(macOS 14.0, *)
struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(host: String, port: Int) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(host: host, port: port))
    }

    var body: some View {
        if viewModel.isExpanded {
            ExpandedView(viewModel: viewModel)
                .frame(minWidth: 320, minHeight: 380)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
        } else {
            CompactDropView(viewModel: viewModel)
                .frame(width: 200, height: 150)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
        }
    }
}

@available(macOS 14.0, *)
struct CompactDropView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Compact header
            VStack(spacing: 4) {
                Text("AI Renamer")
                    .font(.system(size: 14, weight: .semibold))

                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(viewModel.isConnected ? "Ready" : "Offline")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if !viewModel.modelName.isEmpty {
                    Text(viewModel.modelName)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Compact drop zone
            RoundedRectangle(cornerRadius: 10)
                .fill(viewModel.isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .stroke(
                    viewModel.isDragOver ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 3])
                )
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("Drop files here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragOver) { providers in
                    _ = viewModel.handleDrop(providers: providers)
                    return true
                }

            // Browse button
            Button(action: { viewModel.selectFiles() }) {
                Label("Browse", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .task {
            await viewModel.testConnection()
        }
    }
}

@available(macOS 14.0, *)
struct ExpandedView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Ultra-compact header
            VStack(spacing: 6) {
                Text("AI Renamer")
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(viewModel.isConnected ? "Ready" : "Offline")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if !viewModel.modelName.isEmpty {
                    Text(viewModel.modelName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.top, 8)

            // Vertical Drop Zone for narrow width
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .stroke(
                        viewModel.isDragOver ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 3])
                    )
                    .frame(height: 60)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            Text("Drop files or click Browse")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragOver) { providers in
                        _ = viewModel.handleDrop(providers: providers)
                        return true
                    }

                Button(action: { viewModel.selectFiles() }) {
                    Label("Browse Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal)

            // Minimal file count indicator
            if !viewModel.selectedFiles.isEmpty {
                Text("\(viewModel.selectedFiles.count) file\(viewModel.selectedFiles.count == 1 ? "" : "s") selected")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            // Compact Results Area
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Output", systemImage: "text.alignleft")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }

                ScrollView {
                    Text(viewModel.resultsText)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                .background(Color.black.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .cornerRadius(6)
                .frame(minHeight: 120)
            }
            .padding(.horizontal)

            // Vertical button stack for narrow width
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: { Task { await viewModel.processFiles() } }) {
                        Label("Analyze", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canProcess)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(action: { Task { await viewModel.renameFiles() } }) {
                        Label("Rename", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canRename)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: { viewModel.clearAll() }) {
                        Image(systemName: "trash")
                            .frame(width: 20)
                    }
                    .buttonStyle(.borderless)
                    .help("Clear")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .task {
            await viewModel.testConnection()
        }
    }
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published var selectedFiles: [String] = []
    @Published var resultsText: String = ""
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "🔄 Connecting to LM Studio..."
    @Published var modelName: String = ""
    private var pendingAutoRename: Bool = false
    @Published var isDragOver: Bool = false
    @Published var canProcess: Bool = false
    @Published var canRename: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isExpanded: Bool = false
    
    private let client: LMStudioClient
    private var suggestions: [FilenameResponse?] = []
    
    init(host: String, port: Int) {
        self.client = LMStudioClient(host: host, port: port)
    }
    
    func testConnection() async {
        let connected = await client.testConnection()
        isConnected = connected
        connectionStatus = connected ?
            "Connected" :
            "Cannot connect"
        modelName = client.currentModel ?? ""

        if !connected {
            logMessage("❌ Connection Failed - Check LM Studio is running\n")
        }
    }
    
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .jpeg, .png, .gif, .bmp, .tiff, .pdf,
            UTType(filenameExtension: "jpg")!
        ]
        
        if panel.runModal() == .OK {
            let newFiles = panel.urls.map { $0.path }
            addFiles(newFiles)
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Check if shift key is held - if so, don't auto-rename
        let shiftHeld = NSEvent.modifierFlags.contains(.shift)
        pendingAutoRename = !shiftHeld

        let group = DispatchGroup()
        let lock = NSLock()
        var collected: [String] = []

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { continue }
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    lock.lock()
                    collected.append(url.path)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self, !collected.isEmpty else { return }
            self.addFiles(collected)
        }
        return true
    }
    
    private func addFiles(_ files: [String]) {
        let validExtensions = Set(["jpg", "jpeg", "png", "gif", "bmp", "tiff", "pdf"])

        for filePath in files {
            let url = URL(fileURLWithPath: filePath)
            let ext = url.pathExtension.lowercased()

            if validExtensions.contains(ext) && !selectedFiles.contains(filePath) {
                selectedFiles.append(filePath)
            }
        }

        canProcess = !selectedFiles.isEmpty && isConnected
        if !selectedFiles.isEmpty {
            logMessage("Added \(files.count) file(s)\n")
            // Expand the view when files are added
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = true
            }
            // Trigger window resize
            NotificationCenter.default.post(name: .expandWindow, object: nil)

            // Auto-analyze when files are added
            if isConnected && !isProcessing {
                Task {
                    await processFiles()
                }
            }
        }
    }
    
    func processFiles() async {
        guard !isProcessing else { return }
        guard !selectedFiles.isEmpty, isConnected else { return }

        isProcessing = true
        canProcess = false
        canRename = false
        suggestions = []
        
        logMessage("Analyzing files...\n")
        
        for (index, filePath) in selectedFiles.enumerated() {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            logMessage("[\(index + 1)/\(selectedFiles.count)] \(fileName)")
            
            // Determine file type
            let url = URL(fileURLWithPath: filePath)
            guard let fileType = FileType.from(extension: url.pathExtension) else {
                suggestions.append(nil)
                logMessage(" → Unsupported\n")
                continue
            }
            
            // Get suggestion
            do {
                let suggestion = try await client.suggestFilename(for: filePath, fileType: fileType)
                suggestions.append(suggestion)
                logMessage(" → \(suggestion.suggestedFilename) (\(suggestion.confidence)/5)\n")
            } catch {
                suggestions.append(nil)
                logMessage(" → Failed: \(error.localizedDescription)\n")
            }
        }
        
        isProcessing = false
        canProcess = true
        canRename = suggestions.contains { $0 != nil }

        logMessage("Analysis complete\n")

        // Auto-rename if shift wasn't held during drop
        if pendingAutoRename && canRename {
            pendingAutoRename = false
            await performRename(skipConfirmation: true)
        }
    }
    
    func renameFiles() async {
        await performRename(skipConfirmation: false)
    }

    private func performRename(skipConfirmation: Bool) async {
        guard !selectedFiles.isEmpty, !suggestions.isEmpty else { return }

        let validSuggestions = suggestions.compactMap { $0 }.count

        if !skipConfirmation {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = "Confirm Rename"
            alert.informativeText = "Rename \(validSuggestions) file(s) based on AI suggestions?\n\nThis will rename the actual files on your disk.\nMake sure you have backups if needed."
            alert.addButton(withTitle: "Rename")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning

            let response = alert.runModal()
            guard response == .alertFirstButtonReturn else { return }
        }

        logMessage("Renaming...\n")

        var renamedCount = 0

        for (index, filePath) in selectedFiles.enumerated() {
            guard index < suggestions.count,
                  let suggestion = suggestions[index] else { continue }

            let originalURL = URL(fileURLWithPath: filePath)
            _ = originalURL.deletingLastPathComponent()
            let fileExtension = originalURL.pathExtension

            // Find available filename
            let newURL = findAvailableFilename(
                baseURL: originalURL,
                suggestedName: suggestion.suggestedFilename
            )

            do {
                try FileManager.default.moveItem(at: originalURL, to: newURL)
                logMessage("✓ \(originalURL.lastPathComponent) → \(newURL.lastPathComponent)")

                if newURL.lastPathComponent != suggestion.suggestedFilename + "." + fileExtension {
                    logMessage(" (seq)")
                }

                renamedCount += 1
            } catch {
                logMessage("✗ \(originalURL.lastPathComponent)")
            }
        }

        logMessage("\nRenamed \(renamedCount) file(s)\n")
        clearAll()
    }
    
    func clearAll() {
        selectedFiles = []
        suggestions = []
        resultsText = ""
        canProcess = isConnected
        canRename = false
        logMessage("")
        // Collapse back to compact view
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
        // Trigger window resize
        NotificationCenter.default.post(name: .collapseWindow, object: nil)
    }
    
    private func logMessage(_ message: String) {
        resultsText += message + "\n"
    }
    
    private func findAvailableFilename(baseURL: URL, suggestedName: String) -> URL {
        let directory = baseURL.deletingLastPathComponent()
        let fileExtension = baseURL.pathExtension
        var newURL = directory.appendingPathComponent(suggestedName).appendingPathExtension(fileExtension)
        
        if !FileManager.default.fileExists(atPath: newURL.path) {
            return newURL
        }
        
        var counter = 1
        while counter <= 1000 {
            let sequencedName = "\(suggestedName)_\(counter)"
            newURL = directory.appendingPathComponent(sequencedName).appendingPathExtension(fileExtension)
            
            if !FileManager.default.fileExists(atPath: newURL.path) {
                return newURL
            }
            
            counter += 1
        }
        
        // Safety fallback with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let fallbackName = "\(suggestedName)_\(timestamp)"
        return directory.appendingPathComponent(fallbackName).appendingPathExtension(fileExtension)
    }
}

extension Notification.Name {
    static let expandWindow = Notification.Name("expandWindow")
    static let collapseWindow = Notification.Name("collapseWindow")
}
