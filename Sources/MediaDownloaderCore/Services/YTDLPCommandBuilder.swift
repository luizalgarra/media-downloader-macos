import Foundation

public struct YTDLPCommand: Equatable, Sendable {
    public let executableURL: URL
    public let arguments: [String]

    public init(executableURL: URL, arguments: [String]) {
        self.executableURL = executableURL
        self.arguments = arguments
    }
}

public enum YTDLPCommandBuilderError: LocalizedError, Equatable {
    case invalidSourceURL(String)
    case missingYTDLP
    case missingFFmpeg

    public var errorDescription: String? {
        switch self {
        case .invalidSourceURL(let url):
            "URL inválida: \(url)"
        case .missingYTDLP:
            "yt-dlp não está instalado em /opt/homebrew/bin/yt-dlp nem disponível no PATH."
        case .missingFFmpeg:
            "ffmpeg não está instalado em /opt/homebrew/bin/ffmpeg nem disponível no PATH."
        }
    }
}

public struct YTDLPCommandBuilder: Sendable {
    public static let revealPrefix = "MEDIA_DOWNLOADER_OUTPUT:"

    private let toolLocator: ToolLocator

    public init(toolLocator: ToolLocator = ToolLocator()) {
        self.toolLocator = toolLocator
    }

    public func buildCommand(for request: DownloadRequest) throws -> YTDLPCommand {
        let cleanedSourceURL = request.sourceURL
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let normalizedURL = URL(string: cleanedSourceURL),
            let scheme = normalizedURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme)
        else {
            throw YTDLPCommandBuilderError.invalidSourceURL(request.sourceURL)
        }

        guard let ytDlpURL = toolLocator.findYTDLP() else {
            throw YTDLPCommandBuilderError.missingYTDLP
        }

        let destinationPath = request.destinationDirectory.path
        var arguments = commonArguments(destinationPath: destinationPath)

        switch request.mode {
        case .video:
            arguments += [
                "--format", "bv*+ba/b",
                "--merge-output-format", "mp4",
                "--output", "%(title)s.%(ext)s"
            ]

        case .mp3:
            guard let ffmpegURL = toolLocator.findFFmpeg() else {
                throw YTDLPCommandBuilderError.missingFFmpeg
            }

            arguments += [
                "--extract-audio",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--ffmpeg-location", ffmpegURL.path,
                "--output", "%(title)s.%(ext)s"
            ]

        case .playlist:
            arguments += [
                "--yes-playlist",
                "--format", "bv*+ba/b",
                "--merge-output-format", "mp4",
                "--output", "%(playlist_title)s/%(title)s.%(ext)s"
            ]

        case .subtitles:
            arguments += [
                "--skip-download",
                "--write-subs",
                "--write-auto-subs",
                "--sub-langs", "pt.*,pt-BR,en.*",
                "--convert-subs", "srt",
                "--output", "%(title)s.%(ext)s"
            ]
        }

        arguments.append(cleanedSourceURL)

        return YTDLPCommand(
            executableURL: ytDlpURL,
            arguments: arguments
        )
    }

    private func commonArguments(destinationPath: String) -> [String] {
        [
            "--ignore-config",
            "--newline",
            "--progress",
            "--no-warnings",
            "--print",
            "after_move:\(Self.revealPrefix)%(filepath)s",
            "--paths",
            destinationPath
        ]
    }
}


