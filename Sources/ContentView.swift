import SwiftUI
import UniformTypeIdentifiers

@available(macOS 14.0, *)
struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel
    
    init(host: String, port: Int) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(host: host, port: port))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("🤖 AI Image Renamer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Drag & drop files or click to select • Images & PDFs supported")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Connection Status
            HStack {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.connectionStatus)
                    .font(.caption)
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // File Drop Zone
            VStack(spacing: 16) {
                // Drop zone
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .stroke(
                        viewModel.isDragOver ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("Drag & Drop Files Here")
                                .font(.headline)
                            
                            Text("Images: jpg, png, gif, bmp, tiff • PDFs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragOver) { providers in
                        _ = viewModel.handleDrop(providers: providers)
                        return true
                    }
                
                // Select Files Button
                Button("📂 Select Files") {
                    viewModel.selectFiles()
                }
                .buttonStyle(.borderedProminent)
                
                // Selected Files List
                if !viewModel.selectedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Files:")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(viewModel.selectedFiles, id: \.self) { file in
                                    Text("• \(URL(fileURLWithPath: file).lastPathComponent)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxHeight: 100)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Results Area
            VStack(alignment: .leading, spacing: 8) {
                Text("🎯 AI Suggestions")
                    .font(.headline)
                
                ScrollView {
                    Text(viewModel.resultsText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
                .frame(minHeight: 200)
            }
            .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("🤖 Get AI Suggestions") {
                    Task {
                        await viewModel.processFiles()
                    }
                }
                .disabled(!viewModel.canProcess)
                .buttonStyle(.borderedProminent)
                
                Button("✅ Rename Files") {
                    Task {
                        await viewModel.renameFiles()
                    }
                }
                .disabled(!viewModel.canRename)
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("🗑️ Clear") {
                    viewModel.clearAll()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 600, minHeight: 500)
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
    @Published var isDragOver: Bool = false
    @Published var canProcess: Bool = false
    @Published var canRename: Bool = false
    @Published var isProcessing: Bool = false
    
    private let client: LMStudioClient
    private var suggestions: [FilenameResponse?] = []
    
    init(host: String, port: Int) {
        self.client = LMStudioClient(host: host, port: port)
    }
    
    func testConnection() async {
        let connected = await client.testConnection()
        isConnected = connected
        connectionStatus = connected ? 
            "✅ Connected to LM Studio" : 
            "❌ Cannot connect to LM Studio at 127.0.0.1:1234"
        
        if !connected {
            logMessage("❌ Connection Failed\nMake sure LM Studio is running with a model loaded and local server enabled.\n")
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
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.addFiles([url.path])
                        }
                    }
                }
            }
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
        logMessage("📁 Added \(files.count) file(s). Total: \(selectedFiles.count)\n")
    }
    
    func processFiles() async {
        guard !selectedFiles.isEmpty, isConnected else { return }
        
        isProcessing = true
        canProcess = false
        canRename = false
        suggestions = []
        
        logMessage("🤖 Getting AI suggestions...\n")
        
        for (index, filePath) in selectedFiles.enumerated() {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            logMessage("Processing \(index + 1)/\(selectedFiles.count): \(fileName)")
            
            // Determine file type
            let url = URL(fileURLWithPath: filePath)
            guard let fileType = FileType.from(extension: url.pathExtension) else {
                suggestions.append(nil)
                logMessage("  ❌ Unsupported file type\n")
                continue
            }
            
            // Get suggestion
            let suggestion = await client.suggestFilename(for: filePath, fileType: fileType)
            suggestions.append(suggestion)
            
            if let suggestion = suggestion {
                logMessage("  ✅ Suggested: \(suggestion.suggestedFilename)")
                logMessage("  💭 Reasoning: \(suggestion.reasoning)")
                logMessage("  📊 Confidence: \(suggestion.confidence)/5\n")
            } else {
                logMessage("  ❌ Failed to get suggestion\n")
            }
        }
        
        isProcessing = false
        canProcess = true
        canRename = suggestions.contains { $0 != nil }
        
        logMessage("✅ Processing complete!\n")
    }
    
    func renameFiles() async {
        guard !selectedFiles.isEmpty, !suggestions.isEmpty else { return }
        
        let validSuggestions = suggestions.compactMap { $0 }.count
        
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Confirm Rename"
        alert.informativeText = "Rename \(validSuggestions) file(s) based on AI suggestions?\n\nThis will rename the actual files on your disk.\nMake sure you have backups if needed."
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        logMessage("🔄 Renaming files...\n")
        
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
                logMessage("✅ \(originalURL.lastPathComponent) → \(newURL.lastPathComponent)")
                
                if newURL.lastPathComponent != suggestion.suggestedFilename + "." + fileExtension {
                    logMessage("  (sequence number added)")
                }
                
                renamedCount += 1
            } catch {
                logMessage("❌ Failed to rename \(originalURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        logMessage("\n🎉 Successfully renamed \(renamedCount) file(s)!\n")
        clearAll()
    }
    
    func clearAll() {
        selectedFiles = []
        suggestions = []
        resultsText = ""
        canProcess = isConnected
        canRename = false
        logMessage("🗑️ Cleared all files and results.\n")
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
