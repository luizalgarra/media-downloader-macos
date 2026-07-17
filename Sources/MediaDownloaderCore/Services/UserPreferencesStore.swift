import Foundation

public final class UserPreferencesStore {
    private enum Keys {
        static let defaultDestinationPath = "media_downloader.default_destination_path"
    }

    private let defaults: UserDefaults
    private let fallbackDirectoryProvider: @Sendable () -> URL

    public init(
        defaults: UserDefaults = .standard,
        fallbackDirectoryProvider: @escaping @Sendable () -> URL = { UserPreferencesStore.defaultFallbackDirectory() }
    ) {
        self.defaults = defaults
        self.fallbackDirectoryProvider = fallbackDirectoryProvider
    }

    public var defaultDestinationDirectory: URL {
        get {
            if let savedPath = defaults.string(forKey: Keys.defaultDestinationPath), !savedPath.isEmpty {
                return URL(fileURLWithPath: savedPath)
            }

            return fallbackDirectoryProvider()
        }
        set {
            defaults.set(newValue.path, forKey: Keys.defaultDestinationPath)
        }
    }

    public static func defaultFallbackDirectory() -> URL {
        if let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            return downloadsDirectory
        }

        return FileManager.default.homeDirectoryForCurrentUser
    }
}
