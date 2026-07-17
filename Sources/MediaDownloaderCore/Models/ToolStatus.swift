import Foundation

public struct ToolStatus: Equatable, Sendable {
    public let ytDlpURL: URL?
    public let ffmpegURL: URL?

    public init(ytDlpURL: URL?, ffmpegURL: URL?) {
        self.ytDlpURL = ytDlpURL
        self.ffmpegURL = ffmpegURL
    }

    public var missingToolsMessage: String? {
        var missing: [String] = []

        if ytDlpURL == nil {
            missing.append("yt-dlp não encontrado em /opt/homebrew/bin/yt-dlp nem no PATH.")
        }

        if ffmpegURL == nil {
            missing.append("ffmpeg não encontrado em /opt/homebrew/bin/ffmpeg nem no PATH.")
        }

        guard !missing.isEmpty else {
            return nil
        }

        return missing.joined(separator: " ")
    }
}
