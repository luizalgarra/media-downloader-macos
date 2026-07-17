import Foundation

public struct DownloadRequest: Equatable, Sendable {
    public let sourceURL: String
    public let destinationDirectory: URL
    public let mode: DownloadMode

    public init(sourceURL: String, destinationDirectory: URL, mode: DownloadMode) {
        self.sourceURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.destinationDirectory = destinationDirectory
        self.mode = mode
    }
}
