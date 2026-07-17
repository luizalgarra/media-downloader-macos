import Foundation

public struct ParsedOutputLine: Equatable, Sendable {
    public let message: String
    public let progress: Double?
    public let revealedPath: String?

    public init(message: String, progress: Double?, revealedPath: String?) {
        self.message = message
        self.progress = progress
        self.revealedPath = revealedPath
    }
}

public struct YTDLPOutputParser: Sendable {
    public init() {}

    public func parse(_ rawLine: String) -> ParsedOutputLine? {
        let trimmedLine = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else {
            return nil
        }

        if trimmedLine.hasPrefix(YTDLPCommandBuilder.revealPrefix) {
            let outputPath = String(trimmedLine.dropFirst(YTDLPCommandBuilder.revealPrefix.count))
            return ParsedOutputLine(
                message: "Arquivo final: \(outputPath)",
                progress: nil,
                revealedPath: outputPath
            )
        }

        return ParsedOutputLine(
            message: trimmedLine,
            progress: Self.extractProgress(from: trimmedLine),
            revealedPath: nil
        )
    }

    private static func extractProgress(from line: String) -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)%"#
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard
            let match = regularExpression.firstMatch(in: line, range: range),
            let captureRange = Range(match.range(at: 1), in: line),
            let percentage = Double(line[captureRange])
        else {
            return nil
        }

        return percentage / 100
    }
}
