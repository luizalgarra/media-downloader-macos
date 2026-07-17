import Foundation

public final class DownloadHistoryStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() -> [DownloadHistoryEntry] {
        guard
            FileManager.default.fileExists(atPath: fileURL.path),
            let data = try? Data(contentsOf: fileURL)
        else {
            return []
        }

        return (try? decoder.decode([DownloadHistoryEntry].self, from: data)) ?? []
    }

    public func save(_ entries: [DownloadHistoryEntry]) throws {
        try ensureParentDirectoryExists()
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    @discardableResult
    public func add(_ entry: DownloadHistoryEntry) throws -> [DownloadHistoryEntry] {
        var currentEntries = load()
        currentEntries.insert(entry, at: 0)
        try save(currentEntries)
        return currentEntries
    }

    public static func defaultFileURL() -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser

        return baseDirectory
            .appendingPathComponent("MediaDownloader", isDirectory: true)
            .appendingPathComponent("download-history.json")
    }

    private func ensureParentDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
