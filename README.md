# Media Downloader

Aplicativo nativo para macOS que funciona como interface gráfica do `yt-dlp`, com suporte a download de vídeo em MP4, extração de MP3, playlists, legendas, progresso em tempo real e histórico persistente.

## Tecnologias

- Swift 6
- SwiftUI
- Arquitetura MVVM
- `Process` com argumentos separados (sem shell)
- Compatível com macOS 14+
- Preparado para Apple Silicon via Homebrew (`/opt/homebrew`)

## Funcionalidades implementadas

- Campo para colar URL e botão **Colar**
- Botões de ação para:
  - **Baixar Vídeo**
  - **Baixar MP3**
  - **Baixar Playlist**
  - **Baixar Legendas**
- Seleção e persistência da pasta padrão de destino
- Barra de progresso baseada na saída em tempo real do `yt-dlp`
- Área de log em tempo real
- Botão **Cancelar**
- Histórico persistente dos downloads
- Detecção automática de:
  - `yt-dlp` em `/opt/homebrew/bin/yt-dlp` ou no `PATH`
  - `ffmpeg` em `/opt/homebrew/bin/ffmpeg` ou no `PATH`
- Alerta visual quando alguma dependência não está instalada
- Revelação do arquivo final no Finder ao concluir
- Ícone moderno em SVG + conjunto PNG em `Assets.xcassets`

## Estrutura do projeto

```text
Sources/
├── MediaDownloaderApp/
│   ├── App/
│   ├── Resources/
│   ├── ViewModels/
│   └── Views/
└── MediaDownloaderCore/
    ├── Models/
    └── Services/
Tests/
└── MediaDownloaderCoreTests/
```

## Arquitetura

### Views
A interface SwiftUI fica em `Sources/MediaDownloaderApp/Views/ContentView.swift`.

### ViewModels
A orquestração da UI fica em `Sources/MediaDownloaderApp/ViewModels/DownloadViewModel.swift`.

### Models
Os tipos de domínio (`DownloadMode`, `DownloadRequest`, `DownloadHistoryEntry`, `ToolStatus`) ficam em `Sources/MediaDownloaderCore/Models`.

### Services
Os serviços ficam em `Sources/MediaDownloaderCore/Services`:

- `DownloadService`: executa o `yt-dlp` via `Process`
- `YTDLPCommandBuilder`: monta argumentos seguros e separados
- `ToolLocator`: localiza `yt-dlp` e `ffmpeg`
- `UserPreferencesStore`: salva a pasta padrão do usuário
- `DownloadHistoryStore`: persiste o histórico em JSON
- `YTDLPOutputParser`: extrai progresso e caminho final do arquivo

## Requisitos no macOS

Instale as dependências com Homebrew:

```bash
brew install yt-dlp ffmpeg
```

Os caminhos preferenciais esperados são:

- `/opt/homebrew/bin/yt-dlp`
- `/opt/homebrew/bin/ffmpeg`

## Como abrir e rodar no macOS

1. Abra o diretório do repositório no Xcode 16+.
2. Selecione o target executável `MediaDownloaderApp`.
3. Rode em **My Mac**.
4. Cole a URL desejada.
5. Escolha a pasta de destino.
6. Clique no tipo de download desejado.

> Fora do macOS, o executável mostra apenas uma mensagem informando que a interface deve ser aberta em um Mac.

## Modos de download

### Vídeo (MP4)
Usa a melhor combinação de vídeo/áudio disponível e força saída em MP4:

- `-f bv*+ba/b`
- `--merge-output-format mp4`

### MP3
Extrai áudio com `ffmpeg`:

- `-x`
- `--audio-format mp3`
- `--audio-quality 0`
- `--ffmpeg-location <caminho>`

### Playlist
Baixa playlists inteiras organizando os arquivos por nome da playlist.

### Legendas
Baixa legendas em português e inglês quando disponíveis:

- `--write-subs`
- `--write-auto-subs`
- `--sub-langs pt.*,pt-BR,en.*`
- `--convert-subs srt`
- `--skip-download`

## Preferências e histórico

- A pasta padrão é salva via `UserDefaults`
- O histórico é salvo em JSON em `Application Support/MediaDownloader/download-history.json`

## Distribuição como `.app`

O projeto está estruturado como app SwiftUI com target executável separado e recursos visuais prontos para empacotamento no macOS. Em um Mac com Xcode, a distribuição pode ser preparada gerando o aplicativo a partir do target `MediaDownloaderApp` e exportando o bundle `.app` para assinatura/notarização.

## Testes

Foram adicionados testes unitários básicos para:

- localização de dependências
- montagem dos comandos do `yt-dlp`
- persistência de histórico
- parsing de progresso e caminho final

Execute:

```bash
swift test
```

## Limitações do ambiente de desenvolvimento automatizado

Este repositório foi montado em um ambiente Linux, então a compilação da interface SwiftUI/macOS não pôde ser validada com `xcodebuild`. Ainda assim:

- o núcleo compartilhado foi testado com `swift test`
- o executável foi verificado com `swift run MediaDownloaderApp`
- o código da UI foi isolado com `#if os(macOS)` para permanecer compatível com o ambiente de CI atual
