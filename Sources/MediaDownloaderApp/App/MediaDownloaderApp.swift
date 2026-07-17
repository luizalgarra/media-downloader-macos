#if os(macOS)
import SwiftUI
import AppKit

@available(macOS 14.0, *)
struct MediaDownloaderApp: App {
    @State private var viewModel = DownloadViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)

        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup("Media Downloader") {
            ContentView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 980, height: 760)
    }
}
#endif
