import Foundation

struct RenameHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let directory: String
    let originalName: String
    let newName: String

    init(directory: String, originalName: String, newName: String) {
        self.id = UUID()
        self.date = Date()
        self.directory = directory
        self.originalName = originalName
        self.newName = newName
    }
}

final class RenameHistoryStore {
    static let shared = RenameHistoryStore()

    private let fileURL: URL
    private let lock = NSLock()
    private let maxEntries = 500

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("AI Image Renamer", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("history.json")
    }

    func load() -> [RenameHistoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return loadUnlocked()
    }

    func append(_ entry: RenameHistoryEntry) {
        lock.lock()
        defer { lock.unlock() }
        var entries = loadUnlocked()
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        writeUnlocked(entries)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        writeUnlocked([])
    }

    private func loadUnlocked() -> [RenameHistoryEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([RenameHistoryEntry].self, from: data)) ?? []
    }

    private func writeUnlocked(_ entries: [RenameHistoryEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
