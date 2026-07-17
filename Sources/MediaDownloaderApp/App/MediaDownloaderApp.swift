#if os(macOS)
import SwiftUI

@available(macOS 14.0, *)
struct MediaDownloaderApp: App {
    @State private var viewModel = DownloadViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 980, height: 760)
    }
}
#endif
