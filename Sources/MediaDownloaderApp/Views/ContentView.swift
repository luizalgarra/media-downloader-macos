#if os(macOS)
import SwiftUI
import MediaDownloaderCore

@available(macOS 14.0, *)
struct ContentView: View {
    @Bindable var viewModel: DownloadViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            urlSection
            destinationSection
            actionSection
            progressSection
            logSection
            historySection
        }
        .padding(20)
        .frame(minWidth: 960, minHeight: 720)
        .alert(
            "Atenção",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.alertMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.alertMessage ?? "")
            }
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Media Downloader")
                .font(.largeTitle.bold())
            Text("Interface nativa para o yt-dlp com progresso, log em tempo real e histórico de downloads.")
                .foregroundStyle(.secondary)

            if let toolStatusMessage = viewModel.toolStatusMessage {
                Label(toolStatusMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
    }

    private var urlSection: some View {
        GroupBox("URL") {
            HStack(spacing: 12) {
                TextField("Cole aqui a URL do vídeo, áudio ou playlist", text: $viewModel.urlInput)
                    .textFieldStyle(.roundedBorder)
                Button("Colar") {
                    viewModel.pasteURLFromClipboard()
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
    }

    private var destinationSection: some View {
        GroupBox("Pasta de destino") {
            HStack(spacing: 12) {
                TextField("Pasta de destino", text: $viewModel.destinationPath)
                    .textFieldStyle(.roundedBorder)
                Button("Escolher Pasta") {
                    viewModel.chooseDestinationFolder()
                }
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 12) {
            ForEach(DownloadMode.allCases) { mode in
                Button(mode.title) {
                    viewModel.startDownload(mode: mode)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDownloading)
            }

            Spacer()

            Button("Cancelar", role: .destructive) {
                viewModel.cancelDownload()
            }
            .disabled(!viewModel.isDownloading)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: viewModel.progress, total: 1)
                .tint(.accentColor)
            Text(viewModel.statusText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var logSection: some View {
        GroupBox("Log em tempo real") {
            ScrollView {
                Text(viewModel.logText.isEmpty ? "Nenhum evento registrado ainda." : viewModel.logText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 240)
        }
    }

    private var historySection: some View {
        GroupBox("Histórico dos downloads") {
            List(viewModel.history) { entry in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.mode.title)
                            .font(.headline)
                        Text(entry.sourceURL)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Text(entry.destinationPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(statusLabel(for: entry.status))
                            .font(.caption.bold())
                            .foregroundStyle(statusColor(for: entry.status))
                        Button("Revelar") {
                            viewModel.revealHistoryEntry(entry)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 220)
        }
    }

    private func statusLabel(for status: DownloadHistoryStatus) -> String {
        switch status {
        case .completed:
            "Concluído"
        case .failed:
            "Falhou"
        case .cancelled:
            "Cancelado"
        }
    }

    private func statusColor(for status: DownloadHistoryStatus) -> Color {
        switch status {
        case .completed:
            .green
        case .failed:
            .red
        case .cancelled:
            .orange
        }
    }
}
#endif
