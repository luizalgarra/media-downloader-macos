import Foundation

public enum DownloadMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case video
    case mp3
    case playlist
    case subtitles

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .video:
            "Baixar Vídeo"
        case .mp3:
            "Baixar MP3"
        case .playlist:
            "Baixar Playlist"
        case .subtitles:
            "Baixar Legendas"
        }
    }
}
