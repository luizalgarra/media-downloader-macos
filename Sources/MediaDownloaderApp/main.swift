#if os(macOS)
import SwiftUI

if #available(macOS 14.0, *) {
    MediaDownloaderApp.main()
} else {
    fatalError("Media Downloader requer macOS 14 ou superior.")
}
#else
import Foundation

print("Media Downloader é um aplicativo nativo para macOS 14+ e deve ser aberto no Xcode em um Mac.")
#endif
