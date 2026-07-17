import XCTest
@testable import MediaDownloaderCore

final class ToolLocatorTests: XCTestCase {
    func testPrefersHomebrewLocationWhenAvailable() {
        let locator = ToolLocator(
            executableChecker: { path in
                path == "/opt/homebrew/bin/yt-dlp"
            },
            environmentPath: "/usr/local/bin:/usr/bin"
        )

        XCTAssertEqual(locator.findYTDLP()?.path, "/opt/homebrew/bin/yt-dlp")
    }

    func testFallsBackToPATHWhenPreferredLocationIsUnavailable() {
        let locator = ToolLocator(
            executableChecker: { path in
                path == "/usr/local/bin/ffmpeg"
            },
            environmentPath: "/usr/local/bin:/usr/bin"
        )

        XCTAssertEqual(locator.findFFmpeg()?.path, "/usr/local/bin/ffmpeg")
    }
}
