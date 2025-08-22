import Foundation

class FileProcessor {
    private let client: LMStudioClient
    
    init(host: String = "127.0.0.1", port: Int = 1234) {
        self.client = LMStudioClient(host: host, port: port)
    }
    
    func processFiles(_ filePaths: [String], dryRun: Bool = false, autoApprove: Bool = false) async throws {
        print("🤖 AI File Renamer - Command Line Interface")
        print(String(repeating: "=", count: 50))
        
        // Collect valid files
        print("📂 Collecting files...")
        let validFiles = collectValidFiles(from: filePaths)
        
        guard !validFiles.isEmpty else {
            print("❌ No valid files found!")
            print("Supported formats: jpg, jpeg, png, gif, bmp, tiff, pdf")
            Foundation.exit(1)
        }
        
        print("✅ Found \(validFiles.count) file(s) to process")
        
        // Test connection
        print("\n🔗 Connecting to LM Studio...")
        guard await client.testConnection() else {
            print("❌ Cannot connect to LM Studio!")
            print("Make sure LM Studio is running with a model loaded and local server enabled.")
            Foundation.exit(1)
        }
        
        print("✅ Connected to LM Studio!")
        
        // Process files
        print("\n🚀 Processing \(validFiles.count) file(s)...")
        print(String(repeating: "=", count: 50))
        
        var processed = 0
        var renamed = 0
        
        for (index, filePath) in validFiles.enumerated() {
            let url = URL(fileURLWithPath: filePath)
            let originalName = url.lastPathComponent
            
            print("\n[\(index + 1)/\(validFiles.count)] Processing: \(originalName)")
            
            // Determine file type
            guard let fileType = FileType.from(extension: url.pathExtension) else {
                print("❌ Unsupported file type")
                continue
            }
            
            // Get AI suggestion
            print("🤖 Getting AI suggestion...")
            guard let suggestion = await client.suggestFilename(for: filePath, fileType: fileType) else {
                print("❌ Failed to get AI suggestion")
                continue
            }
            
            processed += 1
            
            // Get user approval (unless auto-approve)
            let approvedName: String?
            if autoApprove {
                approvedName = suggestion.suggestedFilename
                print("✅ Auto-approved: \(approvedName!)")
            } else {
                approvedName = getUserApproval(originalName: originalName, suggestion: suggestion)
            }
            
            guard let finalName = approvedName else {
                print("⏭️  Skipped")
                continue
            }
            
            // Find available filename
            let newURL = findAvailableFilename(baseURL: url, suggestedName: finalName)
            
            if dryRun {
                print("🔍 DRY RUN: Would rename to: \(newURL.lastPathComponent)")
                if newURL.lastPathComponent != finalName + "." + url.pathExtension {
                    print("   (sequence number would be added)")
                }
                renamed += 1
            } else {
                do {
                    try FileManager.default.moveItem(at: url, to: newURL)
                    print("✅ Renamed: \(originalName) → \(newURL.lastPathComponent)")
                    if newURL.lastPathComponent != finalName + "." + url.pathExtension {
                        print("   (sequence number added)")
                    }
                    renamed += 1
                } catch {
                    print("❌ Failed to rename: \(error.localizedDescription)")
                }
            }
        }
        
        // Summary
        print("\n" + String(repeating: "=", count: 50))
        print("📊 Summary:")
        print("   Files processed: \(processed)")
        print("   Files \(dryRun ? "would be " : "")renamed: \(renamed)")
        print("   Files skipped: \(validFiles.count - processed)")
        
        if dryRun {
            print("\n💡 Run without --dry-run to actually rename files")
        }
        
        print("\n🎉 Done!")
    }
    
    private func collectValidFiles(from paths: [String]) -> [String] {
        let validExtensions = Set(["jpg", "jpeg", "png", "gif", "bmp", "tiff", "pdf"])
        var files: [String] = []
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            
            if FileManager.default.fileExists(atPath: path) {
                var isDirectory: ObjCBool = false
                FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                
                if isDirectory.boolValue {
                    // Handle directory - find all supported files
                    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                        for case let fileURL as URL in enumerator {
                            if validExtensions.contains(fileURL.pathExtension.lowercased()) {
                                files.append(fileURL.path)
                            }
                        }
                    }
                } else {
                    // Handle single file
                    if validExtensions.contains(url.pathExtension.lowercased()) {
                        files.append(path)
                    }
                }
            }
        }
        
        return Array(Set(files)).sorted() // Remove duplicates and sort
    }
    
    private func getUserApproval(originalName: String, suggestion: FilenameResponse) -> String? {
        print("\n📁 Original: \(originalName)")
        print("🤖 Suggested: \(suggestion.suggestedFilename)")
        print("💭 Reasoning: \(suggestion.reasoning)")
        print("📊 Confidence: \(suggestion.confidence)/5")
        
        while true {
            print("\n👤 Action? [y]es/[n]o/[e]dit/[s]kip: ", terminator: "")
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                continue
            }
            
            switch input {
            case "y", "yes", "":
                return suggestion.suggestedFilename
            case "n", "no", "s", "skip":
                return nil
            case "e", "edit":
                print("✏️  Enter custom filename (without extension): ", terminator: "")
                if let customName = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !customName.isEmpty {
                    return customName
                } else {
                    print("❌ Invalid filename, try again.")
                }
            default:
                print("❌ Invalid choice. Use y/n/e/s")
            }
        }
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
