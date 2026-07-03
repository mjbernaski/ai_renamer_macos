import Foundation

/// User-editable configuration, stored as JSON so the LM Studio address, the
/// default model, and thinking behavior can be changed without rebuilding.
///
/// Location: ~/Library/Application Support/AIImageRenamer/config.json
/// (created with defaults on first launch).
struct AppConfig: Codable {
    var host: String = "127.0.0.1"
    var port: Int = 1234
    /// Preferred model to auto-select when connecting. With LM Link active, a
    /// model hosted on another machine (e.g. Vengeance) is served through the
    /// local server, so localhost + this model id is all that's needed.
    var defaultModel: String? = "nvidia/nemotron-3-nano-omni"
    /// Suppress reasoning/"thinking" output (sends reasoning_effort: none).
    var disableThinking: Bool = true

    init() {}

    // Tolerate partial/older config files: any missing key falls back to default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        host = try c.decodeIfPresent(String.self, forKey: .host) ?? "127.0.0.1"
        port = try c.decodeIfPresent(Int.self, forKey: .port) ?? 1234
        defaultModel = try c.decodeIfPresent(String.self, forKey: .defaultModel) ?? "nvidia/nemotron-3-nano-omni"
        disableThinking = try c.decodeIfPresent(Bool.self, forKey: .disableThinking) ?? true
    }

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("AIImageRenamer/config.json")
    }

    /// Load config, writing a default file the first time so it's easy to find and edit.
    static func load() -> AppConfig {
        let url = fileURL
        if let data = try? Data(contentsOf: url),
           let cfg = try? JSONDecoder().decode(AppConfig.self, from: data) {
            return cfg
        }
        let def = AppConfig()
        def.save()
        return def
    }

    func save() {
        let url = AppConfig.fileURL
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) {
            try? data.write(to: url)
        }
    }
}
