import Foundation

public enum DownloadHistoryStatus: String, Codable, Sendable {
    case completed
    case failed
    case cancelled
}

public struct DownloadHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let sourceURL: String
    public let mode: DownloadMode
    public let destinationPath: String
    public let outputPath: String?
    public let status: DownloadHistoryStatus

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        sourceURL: String,
        mode: DownloadMode,
        destinationPath: String,
        outputPath: String?,
        status: DownloadHistoryStatus
    ) {
        self.id = id
        self.date = date
        self.sourceURL = sourceURL
        self.mode = mode
        self.destinationPath = destinationPath
        self.outputPath = outputPath
        self.status = status
    }
}
