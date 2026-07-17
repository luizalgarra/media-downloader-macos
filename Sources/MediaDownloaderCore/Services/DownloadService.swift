import Foundation
#if os(macOS)
import AppKit
#endif

public struct DownloadCompletion: Equatable, Sendable {
    public let outputPath: String?

    public init(outputPath: String?) {
        self.outputPath = outputPath
    }
}

public enum DownloadServiceError: LocalizedError, Equatable {
    case alreadyRunning
    case launchFailed(String)
    case processFailed(Int32)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            "Já existe um download em andamento."
        case .launchFailed(let message):
            "Falha ao iniciar o download: \(message)"
        case .processFailed(let status):
            "O yt-dlp finalizou com código \(status)."
        case .cancelled:
            "Download cancelado pelo usuário."
        }
    }
}

public final class DownloadService: @unchecked Sendable {
    private let commandBuilder: YTDLPCommandBuilder
    private let outputParser: YTDLPOutputParser
    private let processFactory: @Sendable () -> Process
    private let stateQueue = DispatchQueue(label: "media-downloader.download-service.state")

    private var activeProcess: Process?
    private var isCancelled = false

    public init(
        commandBuilder: YTDLPCommandBuilder = YTDLPCommandBuilder(),
        outputParser: YTDLPOutputParser = YTDLPOutputParser(),
        processFactory: @escaping @Sendable () -> Process = { Process() }
    ) {
        self.commandBuilder = commandBuilder
        self.outputParser = outputParser
        self.processFactory = processFactory
    }

    public func start(
        request: DownloadRequest,
        onLog: @escaping @Sendable (String) -> Void,
        onProgress: @escaping @Sendable (Double) -> Void,
        onCompletion: @escaping @Sendable (Result<DownloadCompletion, Error>) -> Void
    ) throws {
        let command = try commandBuilder.buildCommand(for: request)
        let process = processFactory()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdoutAccumulator = LineAccumulator()
        let stderrAccumulator = LineAccumulator()
        let revealedOutputPath = LockedValue<String?>(nil)

        try stateQueue.sync {
            if activeProcess != nil {
                throw DownloadServiceError.alreadyRunning
            }

            activeProcess = process
            isCancelled = false
        }

        let lineHandler: @Sendable (String) -> Void = { [outputParser] line in
            guard let parsedLine = outputParser.parse(line) else {
                return
            }

            if let progress = parsedLine.progress {
                onProgress(progress)
            }

            if let revealedPath = parsedLine.revealedPath {
                revealedOutputPath.set(revealedPath)
            }

            onLog(parsedLine.message)
        }

        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = nil

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                stdoutAccumulator.flush(using: lineHandler)
                return
            }

            stdoutAccumulator.append(data, using: lineHandler)
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                stderrAccumulator.flush(using: lineHandler)
                return
            }

            stderrAccumulator.append(data, using: lineHandler)
        }

        process.terminationHandler = { [weak self] terminatedProcess in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            stdoutAccumulator.flush(using: lineHandler)
            stderrAccumulator.flush(using: lineHandler)

            let wasCancelled = self?.stateQueue.sync { () -> Bool in
                let cancelled = self?.isCancelled ?? false
                self?.activeProcess = nil
                self?.isCancelled = false
                return cancelled
            } ?? false

            let outputPath = revealedOutputPath.get()

            if wasCancelled {
                onCompletion(.failure(DownloadServiceError.cancelled))
                return
            }

            if terminatedProcess.terminationStatus == 0 {
                onProgress(1)
                self?.revealInFinder(outputPath: outputPath, fallbackDirectory: request.destinationDirectory)
                onCompletion(.success(DownloadCompletion(outputPath: outputPath)))
            } else {
                onCompletion(.failure(DownloadServiceError.processFailed(terminatedProcess.terminationStatus)))
            }
        }

        do {
            try process.run()
            onLog("Iniciando \(request.mode.title) para \(request.sourceURL)")
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            stateQueue.sync {
                activeProcess = nil
                isCancelled = false
            }
            throw DownloadServiceError.launchFailed(error.localizedDescription)
        }
    }

    public func cancel() {
        stateQueue.sync {
            isCancelled = true
            activeProcess?.terminate()
        }
    }

    private func revealInFinder(outputPath: String?, fallbackDirectory: URL) {
        #if os(macOS)
        let targetURL = outputPath.map(URL.init(fileURLWithPath:)) ?? fallbackDirectory
        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
        #endif
    }
}

private final class LineAccumulator: @unchecked Sendable {
    private var buffer = Data()
    private let lock = NSLock()

    func append(_ data: Data, using handler: @escaping @Sendable (String) -> Void) {
        lock.lock()
        buffer.append(data)
        let chunks = drainCompleteLines()
        lock.unlock()

        for chunk in chunks {
            handler(chunk)
        }
    }

    func flush(using handler: @escaping @Sendable (String) -> Void) {
        lock.lock()
        let data = buffer
        buffer.removeAll(keepingCapacity: false)
        lock.unlock()

        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
            return
        }

        handler(text)
    }

    private func drainCompleteLines() -> [String] {
        guard !buffer.isEmpty else {
            return []
        }

        let bytes = Array(buffer)
        var startIndex = 0
        var lines: [String] = []

        for (index, byte) in bytes.enumerated() where byte == 10 || byte == 13 {
            if index > startIndex {
                let lineData = Data(bytes[startIndex..<index])
                if let line = String(data: lineData, encoding: .utf8) {
                    lines.append(line)
                }
            }
            startIndex = index + 1
        }

        if startIndex > 0 {
            buffer.removeSubrange(0..<startIndex)
        }

        return lines
    }
}

private final class LockedValue<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func get() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: Value) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
}
