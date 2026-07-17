import Foundation

public struct ToolLocator: Sendable {
    public typealias ExecutableChecker = @Sendable (String) -> Bool

    private let executableChecker: ExecutableChecker
    private let environmentPath: String?

    public init(
        executableChecker: @escaping ExecutableChecker = { FileManager.default.isExecutableFile(atPath: $0) },
        environmentPath: String? = ProcessInfo.processInfo.environment["PATH"]
    ) {
        self.executableChecker = executableChecker
        self.environmentPath = environmentPath
    }

    public func findYTDLP() -> URL? {
        findExecutable(named: "yt-dlp", preferredLocations: ["/opt/homebrew/bin/yt-dlp"])
    }

    public func findFFmpeg() -> URL? {
        findExecutable(named: "ffmpeg", preferredLocations: ["/opt/homebrew/bin/ffmpeg"])
    }

    public func status() -> ToolStatus {
        ToolStatus(ytDlpURL: findYTDLP(), ffmpegURL: findFFmpeg())
    }

    private func findExecutable(named toolName: String, preferredLocations: [String]) -> URL? {
        for preferredLocation in preferredLocations where executableChecker(preferredLocation) {
            return URL(fileURLWithPath: preferredLocation)
        }

        let pathDirectories = (environmentPath ?? "")
            .split(separator: ":")
            .map(String.init)
            .filter { !$0.isEmpty }

        for directory in pathDirectories {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(toolName).path
            if executableChecker(candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }

        return nil
    }
}
