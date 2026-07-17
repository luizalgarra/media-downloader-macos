#if os(macOS)
import AppKit
import Foundation
import MediaDownloaderCore
import Observation

@MainActor
@Observable
@available(macOS 14.0, *)
final class DownloadViewModel {
    var urlInput = ""
    var destinationPath: String
    var progress: Double = 0
    var logText = ""
    var statusText = "Pronto para baixar"
    var isDownloading = false
    var alertMessage: String?
    var history: [DownloadHistoryEntry]
    var toolStatusMessage: String?

    private let preferencesStore: UserPreferencesStore
    private let historyStore: DownloadHistoryStore
    private let downloadService: DownloadService
    private let toolLocator: ToolLocator

    init(
        preferencesStore: UserPreferencesStore = UserPreferencesStore(),
        historyStore: DownloadHistoryStore = DownloadHistoryStore(),
        downloadService: DownloadService = DownloadService(),
        toolLocator: ToolLocator = ToolLocator()
    ) {
        self.preferencesStore = preferencesStore
        self.historyStore = historyStore
        self.downloadService = downloadService
        self.toolLocator = toolLocator
        self.destinationPath = preferencesStore.defaultDestinationDirectory.path
        self.history = historyStore.load().sorted { $0.date > $1.date }
        refreshToolStatus()
    }

    func pasteURLFromClipboard() {
        if let clipboardValue = NSPasteboard.general.string(forType: .string) {
            urlInput = clipboardValue
        }
    }

    func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Selecionar"
        panel.directoryURL = URL(fileURLWithPath: destinationPath)

        if panel.runModal() == .OK, let selectedURL = panel.url {
            updateDestinationPath(selectedURL.path)
        }
    }

    func updateDestinationPath(_ newPath: String) {
        let cleanedPath = newPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedPath.isEmpty else {
            return
        }

        destinationPath = cleanedPath
        preferencesStore.defaultDestinationDirectory = URL(fileURLWithPath: cleanedPath)
    }

    func startDownload(mode: DownloadMode) {
        guard !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Cole uma URL antes de iniciar o download."
            return
        }

        isDownloading = true
        progress = 0
        statusText = "Preparando download..."
        logText = ""
        refreshToolStatus()

        let request = DownloadRequest(
            sourceURL: urlInput,
            destinationDirectory: URL(fileURLWithPath: destinationPath),
            mode: mode
        )

        do {
            try downloadService.start(
                request: request,
                onLog: { [weak self] line in
                    Task { @MainActor in
                        self?.appendLog(line)
                    }
                },
                onProgress: { [weak self] value in
                    Task { @MainActor in
                        self?.progress = value
                        self?.statusText = "Progresso: \(Int((value * 100).rounded()))%"
                    }
                },
                onCompletion: { [weak self] result in
                    Task { @MainActor in
                        self?.handleCompletion(result, request: request)
                    }
                }
            )
        } catch {
            isDownloading = false
            statusText = "Falha ao iniciar"
            alertMessage = error.localizedDescription
            appendLog(error.localizedDescription)
        }
    }

    func cancelDownload() {
        downloadService.cancel()
        appendLog("Solicitação de cancelamento enviada.")
    }

    func revealHistoryEntry(_ entry: DownloadHistoryEntry) {
        let targetPath = entry.outputPath ?? entry.destinationPath
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: targetPath)])
    }

    func refreshToolStatus() {
        toolStatusMessage = toolLocator.status().missingToolsMessage
    }

    private func handleCompletion(_ result: Result<DownloadCompletion, Error>, request: DownloadRequest) {
        isDownloading = false

        switch result {
        case .success(let completion):
            progress = 1
            statusText = "Download concluído"
            appendLog("Download finalizado com sucesso.")
            persistHistoryEntry(
                for: request,
                outputPath: completion.outputPath,
                status: .completed
            )
        case .failure(let error):
            let status: DownloadHistoryStatus = (error as? DownloadServiceError) == .cancelled ? .cancelled : .failed
            statusText = status == .cancelled ? "Download cancelado" : "Falha no download"
            appendLog(error.localizedDescription)
            alertMessage = status == .cancelled ? nil : error.localizedDescription
            persistHistoryEntry(
                for: request,
                outputPath: nil,
                status: status
            )
        }
    }

    private func persistHistoryEntry(for request: DownloadRequest, outputPath: String?, status: DownloadHistoryStatus) {
        let entry = DownloadHistoryEntry(
            sourceURL: request.sourceURL,
            mode: request.mode,
            destinationPath: request.destinationDirectory.path,
            outputPath: outputPath,
            status: status
        )

        do {
            history = try historyStore.add(entry).sorted { $0.date > $1.date }
        } catch {
            appendLog("Não foi possível salvar o histórico: \(error.localizedDescription)")
        }
    }

    private func appendLog(_ line: String) {
        guard !line.isEmpty else {
            return
        }

        if logText.isEmpty {
            logText = line
        } else {
            logText += "\n\(line)"
        }
    }
}
#endif
