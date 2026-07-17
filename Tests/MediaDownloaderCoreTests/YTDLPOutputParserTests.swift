import XCTest
@testable import MediaDownloaderCore

final class YTDLPOutputParserTests: XCTestCase {
    func testExtractsProgress() {
        let parser = YTDLPOutputParser()

        let parsed = parser.parse("[download]  42.3% of 10.00MiB at 1.00MiB/s")

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.progress ?? 0, 0.423, accuracy: 0.0001)
        XCTAssertEqual(parsed?.message, "[download]  42.3% of 10.00MiB at 1.00MiB/s")
    }

    func testExtractsRevealedOutputPath() {
        let parser = YTDLPOutputParser()

        let parsed = parser.parse("MEDIA_DOWNLOADER_OUTPUT:/Users/test/Downloads/video.mp4")

        XCTAssertEqual(parsed?.revealedPath, "/Users/test/Downloads/video.mp4")
        XCTAssertEqual(parsed?.message, "Arquivo final: /Users/test/Downloads/video.mp4")
    }
}
