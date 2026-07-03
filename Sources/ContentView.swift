import SwiftUI
import UniformTypeIdentifiers

@available(macOS 14.0, *)
struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(config: AppConfig) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(config: config))
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
struct ConnectionStatusButton: View {
    @ObservedObject var viewModel: ContentViewModel

    private var statusText: String {
        if viewModel.isConnected { return "Ready" }
        return viewModel.isCheckingConnection ? "Connecting…" : "Offline · Retry"
    }

    var body: some View {
        Button(action: { viewModel.retryConnectionNow() }) {
            HStack(spacing: 4) {
                if viewModel.isCheckingConnection {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.5)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                }
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.isCheckingConnection)
        .help(viewModel.isConnected
              ? "Connected to LM Studio"
              : "Not connected to LM Studio. Click to retry now.")
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

                ConnectionStatusButton(viewModel: viewModel)

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
            viewModel.startConnectionMonitoring()
        }
    }
}

@available(macOS 14.0, *)
struct ExpandedView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Ultra-compact header
            ZStack {
                VStack(spacing: 6) {
                    Text("AI Renamer")
                        .font(.system(size: 16, weight: .semibold))

                    ConnectionStatusButton(viewModel: viewModel)

                    if viewModel.isConnected && !viewModel.availableModels.isEmpty {
                        Picker("Model", selection: Binding(
                            get: { viewModel.modelName },
                            set: { viewModel.selectModel($0) }
                        )) {
                            ForEach(viewModel.availableModels, id: \.self) { id in
                                Text(id).tag(id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.mini)
                        .frame(maxWidth: 240)
                        .help("Choose which loaded model to use for analysis")
                    } else if !viewModel.modelName.isEmpty {
                        Text(viewModel.modelName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.isExpanded = false
                        }
                        NotificationCenter.default.post(name: .collapseWindow, object: nil)
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Collapse")
                    .padding(.trailing, 4)
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

                HStack(spacing: 8) {
                    Button(action: { viewModel.selectFiles() }) {
                        Label("Files", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.isBatchRunning)

                    Button(action: { viewModel.selectFolder() }) {
                        Label("Folder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.isBatchRunning || !viewModel.isConnected)
                    .help("Pick a folder to batch-rename all images and PDFs (recursive)")
                }
            }
            .padding(.horizontal)

            // Batch progress banner
            if viewModel.isBatchRunning || viewModel.batchTotal > 0 {
                BatchProgressView(viewModel: viewModel)
                    .padding(.horizontal)
            }

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
                    Picker("", selection: $viewModel.viewMode) {
                        ForEach(ResultsViewMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.mini)

                    if viewModel.viewMode == .history && !viewModel.history.isEmpty {
                        Button(action: { viewModel.clearHistory() }) {
                            Text("Clear")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                    } else if viewModel.viewMode == .session && !viewModel.sessionRenames.isEmpty {
                        Button(action: { viewModel.clearSession() }) {
                            Text("Clear")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                    }
                }

                ScrollView {
                    switch viewModel.viewMode {
                    case .output:
                        Text(viewModel.resultsText)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                    case .session:
                        if viewModel.sessionRenames.isEmpty {
                            Text("No files renamed this session")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(viewModel.sessionRenames) { entry in
                                    HistoryRow(entry: entry,
                                               onReveal: { viewModel.revealInFinder(entry) })
                                }
                            }
                            .padding(6)
                        }
                    case .history:
                        if viewModel.history.isEmpty {
                            Text("No renames yet")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(viewModel.history) { entry in
                                    HistoryRow(entry: entry,
                                               onReveal: { viewModel.revealInFinder(entry) })
                                }
                            }
                            .padding(6)
                        }
                    }
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

                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                )) {
                    Text("Launch at login")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .disabled(!viewModel.launchAtLoginSupported)
                .help(viewModel.launchAtLoginSupported
                      ? "Automatically start AI Renamer when you log in"
                      : "Available once the app is installed in /Applications")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .task {
            viewModel.startConnectionMonitoring()
        }
    }
}

@available(macOS 14.0, *)
struct BatchProgressView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: viewModel.isBatchRunning ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.isBatchRunning ? .blue : .green)
                Text(viewModel.isBatchRunning ? "Batch in progress" : "Batch complete")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                if viewModel.isBatchRunning {
                    Button(action: { viewModel.stopBatch() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.mini)
                } else {
                    Button(action: { viewModel.dismissBatchSummary() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Dismiss")
                }
            }

            if viewModel.batchTotal > 0 {
                ProgressView(value: Double(viewModel.batchProcessed),
                             total: Double(max(viewModel.batchTotal, 1)))
                    .progressViewStyle(.linear)
                    .controlSize(.mini)
            }

            HStack(spacing: 6) {
                Text("\(viewModel.batchProcessed) / \(viewModel.batchTotal)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("✓ \(viewModel.batchSucceeded)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green)
                if viewModel.batchFailed > 0 {
                    Text("✗ \(viewModel.batchFailed)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.red)
                }
                Spacer()
            }

            if !viewModel.batchCurrentFile.isEmpty {
                Text(viewModel.batchCurrentFile)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
        )
        .cornerRadius(6)
    }
}

@available(macOS 14.0, *)
struct HistoryRow: View {
    let entry: RenameHistoryEntry
    let onReveal: () -> Void

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.newName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 6)
                Text(Self.relative.localizedString(for: entry.date, relativeTo: Date()))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(entry.originalName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onReveal)
        .contextMenu {
            Button("Reveal in Finder", action: onReveal)
        }
        .help("Double-click to reveal in Finder\n\(entry.directory)")
    }
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published var selectedFiles: [String] = []
    @Published var resultsText: String = ""
    @Published var isConnected: Bool = false
    @Published var isCheckingConnection: Bool = false
    @Published var connectionStatus: String = "🔄 Connecting to LM Studio..."
    @Published var modelName: String = ""
    @Published var availableModels: [String] = []
    private var connectionMonitorTask: Task<Void, Never>?
    private var pendingAutoRename: Bool = false
    @Published var isDragOver: Bool = false
    @Published var canProcess: Bool = false
    @Published var canRename: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isExpanded: Bool = false

    @Published var isBatchRunning: Bool = false
    @Published var batchTotal: Int = 0
    @Published var batchProcessed: Int = 0
    @Published var batchSucceeded: Int = 0
    @Published var batchFailed: Int = 0
    @Published var batchCurrentFile: String = ""
    @Published var batchFolder: String = ""
    private var batchStopRequested: Bool = false

    private let client: LMStudioClient
    private var suggestions: [FilenameResponse?] = []
    private let historyStore = RenameHistoryStore.shared
    @Published var history: [RenameHistoryEntry] = []
    @Published var sessionRenames: [RenameHistoryEntry] = []
    @Published var viewMode: ResultsViewMode = .output

    @Published var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    let launchAtLoginSupported: Bool = LaunchAtLogin.isSupported

    init(config: AppConfig) {
        self.client = LMStudioClient(
            host: config.host,
            port: config.port,
            preferredModel: config.defaultModel,
            disableThinking: config.disableThinking
        )
        self.history = historyStore.load()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if let error = LaunchAtLogin.setEnabled(enabled) {
            logMessage("⚠️ Launch at login: \(error)\n")
            // Reflect the true state (the change didn't take).
            launchAtLogin = LaunchAtLogin.isEnabled
        } else {
            launchAtLogin = enabled
        }
    }
    
    func testConnection() async {
        let wasConnected = isConnected
        isCheckingConnection = true
        let connected = await client.testConnection()
        isConnected = connected
        isCheckingConnection = false
        connectionStatus = connected ? "Connected" : "Cannot connect"
        modelName = client.currentModel ?? ""
        availableModels = client.availableModels
        canProcess = !selectedFiles.isEmpty && connected

        // Only log on state transitions so background polling doesn't flood the log.
        if connected && !wasConnected {
            logMessage("✅ Connected to LM Studio\(modelName.isEmpty ? "" : " (\(modelName))")\n")
        } else if !connected && wasConnected {
            logMessage("❌ Lost connection to LM Studio — retrying...\n")
        }
    }

    /// Continuously polls LM Studio so the app recovers on its own once the
    /// server becomes reachable (e.g. LM Studio launched after this app).
    func startConnectionMonitoring() {
        guard connectionMonitorTask == nil else { return }
        connectionMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.testConnection()
                // Poll quickly while offline, back off once connected.
                let delay: UInt64 = self.isConnected ? 15_000_000_000 : 3_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    /// Force an immediate connection check (bound to the status indicator).
    func retryConnectionNow() {
        guard !isCheckingConnection else { return }
        Task { await testConnection() }
    }

    /// User picked a model from the dropdown.
    func selectModel(_ id: String) {
        guard id != modelName else { return }
        client.setModel(id)
        modelName = id
        logMessage("Model set to \(id)\n")
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

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose Folder"
        panel.message = "Select a folder. All images and PDFs (including subfolders) will be batch-renamed."

        if panel.runModal() == .OK, let url = panel.urls.first {
            startBatch(folderPath: url.path)
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

        // If any of the dropped/picked paths is a directory, route to batch mode.
        let fm = FileManager.default
        for path in files {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                startBatch(folderPath: path)
                return
            }
        }

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

                let entry = RenameHistoryEntry(
                    directory: originalURL.deletingLastPathComponent().path,
                    originalName: originalURL.lastPathComponent,
                    newName: newURL.lastPathComponent
                )
                history.insert(entry, at: 0)
                sessionRenames.insert(entry, at: 0)
                historyStore.append(entry)

                renamedCount += 1
            } catch {
                logMessage("✗ \(originalURL.lastPathComponent)")
            }
        }

        logMessage("\nRenamed \(renamedCount) file(s)\n")
        if renamedCount > 0 {
            viewMode = .session
        }
        clearAll(collapse: false)
    }
    
    // MARK: - Batch (folder) processing

    func startBatch(folderPath: String) {
        guard !isBatchRunning else { return }
        guard isConnected else {
            logMessage("Cannot start batch: not connected to LM Studio\n")
            return
        }

        let folderURL = URL(fileURLWithPath: folderPath)
        let files = scanFolderForFiles(folderURL)
        if files.isEmpty {
            logMessage("No images or PDFs found in \(folderURL.lastPathComponent)\n")
            return
        }

        batchFolder = folderPath
        batchTotal = files.count
        batchProcessed = 0
        batchSucceeded = 0
        batchFailed = 0
        batchCurrentFile = ""
        batchStopRequested = false
        isBatchRunning = true
        canProcess = false
        canRename = false
        viewMode = .session

        if !isExpanded {
            withAnimation(.easeInOut(duration: 0.3)) { isExpanded = true }
            NotificationCenter.default.post(name: .expandWindow, object: nil)
        }

        logMessage("Batch started: \(files.count) file(s) under \(folderURL.path)\n")

        Task { await runBatch(files: files) }
    }

    func stopBatch() {
        guard isBatchRunning else { return }
        batchStopRequested = true
        logMessage("Stopping after current file...\n")
    }

    func dismissBatchSummary() {
        guard !isBatchRunning else { return }
        batchTotal = 0
        batchProcessed = 0
        batchSucceeded = 0
        batchFailed = 0
        batchFolder = ""
        batchCurrentFile = ""
    }

    private func runBatch(files: [String]) async {
        for filePath in files {
            if batchStopRequested { break }

            let url = URL(fileURLWithPath: filePath)
            batchCurrentFile = url.lastPathComponent

            guard let fileType = FileType.from(extension: url.pathExtension) else {
                batchProcessed += 1
                batchFailed += 1
                continue
            }

            do {
                let suggestion = try await client.suggestFilename(for: filePath, fileType: fileType)
                let newURL = findAvailableFilename(baseURL: url, suggestedName: suggestion.suggestedFilename)
                try FileManager.default.moveItem(at: url, to: newURL)

                let entry = RenameHistoryEntry(
                    directory: url.deletingLastPathComponent().path,
                    originalName: url.lastPathComponent,
                    newName: newURL.lastPathComponent
                )
                history.insert(entry, at: 0)
                sessionRenames.insert(entry, at: 0)
                historyStore.append(entry)

                batchSucceeded += 1
                logMessage("✓ \(url.lastPathComponent) → \(newURL.lastPathComponent)\n")
            } catch {
                batchFailed += 1
                logMessage("✗ \(url.lastPathComponent): \(error.localizedDescription)\n")
            }

            batchProcessed += 1
        }

        let stopped = batchStopRequested
        isBatchRunning = false
        batchStopRequested = false
        batchCurrentFile = ""
        canProcess = !selectedFiles.isEmpty && isConnected

        let summary = "\nBatch \(stopped ? "stopped" : "complete"): \(batchSucceeded) renamed, \(batchFailed) failed, \(batchTotal - batchProcessed) remaining\n"
        logMessage(summary)
    }

    private func scanFolderForFiles(_ folder: URL) -> [String] {
        let validExtensions = Set(["jpg", "jpeg", "png", "gif", "bmp", "tiff", "pdf"])
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var results: [String] = []
        for case let url as URL in enumerator {
            let isFile = (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            guard isFile else { continue }
            if validExtensions.contains(url.pathExtension.lowercased()) {
                results.append(url.path)
            }
        }
        return results
    }

    func clearHistory() {
        history = []
        historyStore.clear()
    }

    func clearSession() {
        sessionRenames = []
    }

    func revealInFinder(_ entry: RenameHistoryEntry) {
        let path = (entry.directory as NSString).appendingPathComponent(entry.newName)
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func clearAll(collapse: Bool = false) {
        selectedFiles = []
        suggestions = []
        resultsText = ""
        canProcess = isConnected
        canRename = false
        if collapse {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = false
            }
            NotificationCenter.default.post(name: .collapseWindow, object: nil)
        }
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

enum ResultsViewMode: String, CaseIterable, Identifiable {
    case output
    case session
    case history

    var id: String { rawValue }

    var label: String {
        switch self {
        case .output: return "Output"
        case .session: return "Session"
        case .history: return "History"
        }
    }

    var systemImage: String {
        switch self {
        case .output: return "text.alignleft"
        case .session: return "list.bullet.rectangle"
        case .history: return "clock.arrow.circlepath"
        }
    }
}
