import XCTest
@testable import MediaDownloaderCore

final class DownloadHistoryStoreTests: XCTestCase {
    func testPersistsEntriesToDisk() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DownloadHistoryStore(fileURL: tempDirectory.appendingPathComponent("history.json"))
        let entry = DownloadHistoryEntry(
            sourceURL: "https://example.com/video",
            mode: .video,
            destinationPath: "/tmp/downloads",
            outputPath: "/tmp/downloads/video.mp4",
            status: .completed
        )

        _ = try store.add(entry)
        let loadedEntries = store.load()

        XCTAssertEqual(loadedEntries.count, 1)
        XCTAssertEqual(loadedEntries.first?.sourceURL, entry.sourceURL)
        XCTAssertEqual(loadedEntries.first?.outputPath, entry.outputPath)
    }
}
