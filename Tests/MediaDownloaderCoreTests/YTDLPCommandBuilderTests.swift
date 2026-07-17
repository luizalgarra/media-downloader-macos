import XCTest
@testable import MediaDownloaderCore

final class YTDLPCommandBuilderTests: XCTestCase {
    func testBuildsMP3CommandWithFFmpegLocation() throws {
        let locator = ToolLocator(
            executableChecker: { path in
                ["/opt/homebrew/bin/yt-dlp", "/opt/homebrew/bin/ffmpeg"].contains(path)
            },
            environmentPath: nil
        )
        let builder = YTDLPCommandBuilder(toolLocator: locator)
        let request = DownloadRequest(
            sourceURL: "https://example.com/video",
            destinationDirectory: URL(fileURLWithPath: "/tmp/downloads"),
            mode: .mp3
        )

        let command = try builder.buildCommand(for: request)

        XCTAssertEqual(command.executableURL.path, "/opt/homebrew/bin/yt-dlp")
        XCTAssertTrue(command.arguments.contains("--ffmpeg-location"))
        XCTAssertTrue(command.arguments.contains("/opt/homebrew/bin/ffmpeg"))
        XCTAssertEqual(command.arguments.last, "https://example.com/video")
    }

    func testBuildsSubtitlesCommandWithExpectedLanguages() throws {
        let locator = ToolLocator(
            executableChecker: { $0 == "/opt/homebrew/bin/yt-dlp" },
            environmentPath: nil
        )
        let builder = YTDLPCommandBuilder(toolLocator: locator)
        let request = DownloadRequest(
            sourceURL: "https://example.com/video",
            destinationDirectory: URL(fileURLWithPath: "/tmp/downloads"),
            mode: .subtitles
        )

        let command = try builder.buildCommand(for: request)

        XCTAssertTrue(command.arguments.contains("--write-subs"))
        XCTAssertTrue(command.arguments.contains("--write-auto-subs"))
        XCTAssertTrue(command.arguments.contains("pt.*,pt-BR,en.*"))
        XCTAssertTrue(command.arguments.contains("--skip-download"))
    }

    func testRejectsInvalidURL() {
        let builder = YTDLPCommandBuilder(
            toolLocator: ToolLocator(
                executableChecker: { _ in true },
                environmentPath: nil
            )
        )
        let request = DownloadRequest(
            sourceURL: "notaurl",
            destinationDirectory: URL(fileURLWithPath: "/tmp/downloads"),
            mode: .video
        )

        XCTAssertThrowsError(try builder.buildCommand(for: request)) { error in
            XCTAssertEqual(error as? YTDLPCommandBuilderError, .invalidSourceURL("notaurl"))
        }
    }
}
