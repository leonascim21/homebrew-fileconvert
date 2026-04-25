import Foundation
import AppKit
import Observation
import UniformTypeIdentifiers

enum ConversionResult: Equatable {
    case singleFile(URL)
    case multipleFiles([URL])

    var revealTarget: URL? {
        switch self {
        case .singleFile(let url): return url
        case .multipleFiles(let urls): return urls.first
        }
    }

    var summary: String {
        switch self {
        case .singleFile(let url): return url.lastPathComponent
        case .multipleFiles(let urls): return "\(urls.count) files"
        }
    }
}

enum ConversionState: Equatable {
    case idle
    case running(Double)
    case succeeded(ConversionResult)
    case failed(String)
    case cancelled

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}

@Observable
@MainActor
final class AppViewModel {
    var route: AppRoute = .landing
    var state: ConversionState = .idle

    var singleImageTarget: SingleImageTarget = .image(.png)
    var pdfOutputFormat: ImageFormat = .png
    var pdfOutputTarget: PDFOutputTarget = .images
    var videoTarget: VideoFormat = .mp4
    var multiImageMode: MultiImageMode = .convertEach
    var multiImageFormat: ImageFormat = .png
    var options: ConversionOptions = .default

    private var currentTask: Task<Void, Never>?

    // MARK: - Intake

    func handleDrop(urls: [URL]) {
        let supported = urls.filter { FormatDetector.isSupported(url: $0) }
        route(to: supported)
    }

    func pickFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Select"
        panel.message = "Choose an image, PDF, video, or Word document — or multiple images / PDFs."
        if panel.runModal() == .OK {
            route(to: panel.urls)
        }
    }

    private func route(to urls: [URL]) {
        guard !urls.isEmpty else {
            state = .failed("No supported files selected.")
            return
        }

        state = .idle

        if urls.count == 1, let url = urls.first {
            let type = FormatDetector.detect(url: url)
            switch FormatDetector.family(for: type) {
            case .image:
                singleImageTarget = .image(.png)
                route = .image(source: url)
            case .pdf:
                pdfOutputFormat = .png
                pdfOutputTarget = .images
                route = .pdf(source: url)
            case .video:
                videoTarget = .mp4
                route = .video(source: url)
            case .document:
                route = .docx(source: url)
            case .none:
                state = .failed("Unsupported file type: \(url.lastPathComponent)")
            }
            return
        }

        let families = urls.map { FormatDetector.family(for: FormatDetector.detect(url: $0)) }

        if families.allSatisfy({ $0 == .image }) {
            multiImageMode = .convertEach
            multiImageFormat = .png
            route = .multiImage(sources: urls)
        } else if families.allSatisfy({ $0 == .pdf }) {
            route = .multiPDF(sources: urls)
        } else {
            state = .failed("Multi-file drops must be all images or all PDFs.")
        }
    }

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
        route = .landing
    }

    func cancel() {
        currentTask?.cancel()
    }

    // MARK: - Conversion entry points

    func startImageConversion() {
        guard case .image(let source) = route else { return }
        let target = singleImageTarget
        let suggested = source.deletingPathExtension().lastPathComponent + "." + target.fileExtension
        guard let destination = promptSaveDestination(
            suggestedName: suggested,
            allowedContentType: target.utTypeForSave
        ) else { return }

        runConversion { [options = self.options] progress in
            switch target {
            case .image(let format):
                try await ImageConverter.convert(
                    sourceURL: source,
                    to: destination,
                    format: format,
                    options: options,
                    progress: progress
                )
            case .pdf:
                try await PDFConverter.imageToPDF(
                    sourceURL: source,
                    destinationURL: destination,
                    progress: progress
                )
            }
            return .singleFile(destination)
        }
    }

    func startPDFConversion() {
        guard case .pdf(let source) = route else { return }
        switch pdfOutputTarget {
        case .images:
            startPDFToImages(source: source)
        case .pdf:
            startPDFCompress(source: source)
        }
    }

    private func startPDFToImages(source: URL) {
        let format = pdfOutputFormat
        guard let destinationDir = promptDirectory(
            message: "Choose a folder for the rendered pages."
        ) else { return }

        runConversion { [options = self.options] progress in
            let outputs = try await PDFConverter.pdfToImages(
                sourceURL: source,
                destinationDirectory: destinationDir,
                format: format,
                options: options,
                progress: progress
            )
            return .multipleFiles(outputs)
        }
    }

    private func startPDFCompress(source: URL) {
        let suggested = source.deletingPathExtension().lastPathComponent + " compressed.pdf"
        guard let destination = promptSaveDestination(
            suggestedName: suggested,
            allowedContentType: .pdf
        ) else { return }

        runConversion { [options = self.options] progress in
            try await PDFConverter.mergePDFs(
                sourceURLs: [source],
                destinationURL: destination,
                compression: options.pdfCompression,
                options: options,
                progress: progress
            )
            return .singleFile(destination)
        }
    }

    func startDocxConversion() {
        guard case .docx(let source) = route else { return }
        let suggested = source.deletingPathExtension().lastPathComponent + ".pdf"
        guard let destination = promptSaveDestination(
            suggestedName: suggested,
            allowedContentType: .pdf
        ) else { return }

        runConversion { progress in
            try await DocumentConverter.docxToPDF(
                sourceURL: source,
                destinationURL: destination,
                progress: progress
            )
            return .singleFile(destination)
        }
    }

    func startVideoConversion() {
        guard case .video(let source) = route else { return }
        let format = videoTarget
        let suggested = source.deletingPathExtension().lastPathComponent + "." + format.fileExtension
        guard let destination = promptSaveDestination(
            suggestedName: suggested,
            allowedContentType: format.utTypeForSave
        ) else { return }

        runConversion { [options = self.options] progress in
            try await VideoConverter.convert(
                sourceURL: source,
                destinationURL: destination,
                format: format,
                options: options,
                progress: progress
            )
            return .singleFile(destination)
        }
    }

    func startMultiImageConversion() {
        guard case .multiImage(let sources) = route else { return }
        let mode = multiImageMode
        let format = multiImageFormat

        switch mode {
        case .convertEach:
            guard let destinationDir = promptDirectory(
                message: "Choose a folder for the converted images."
            ) else { return }

            runConversion { [options = self.options] progress in
                var outputs: [URL] = []
                let total = Double(sources.count)
                for (index, source) in sources.enumerated() {
                    try Task.checkCancellation()
                    let out = OutputNamer.uniqueURL(
                        in: destinationDir,
                        forSource: source,
                        fileExtension: format.fileExtension
                    )
                    try await ImageConverter.convert(
                        sourceURL: source,
                        to: out,
                        format: format,
                        options: options,
                        progress: { _ in }
                    )
                    outputs.append(out)
                    await progress(Double(index + 1) / total)
                }
                return .multipleFiles(outputs)
            }

        case .mergeIntoPDF:
            let firstBase = sources.first?.deletingPathExtension().lastPathComponent ?? "Merged"
            let suggested = "\(firstBase) merged.pdf"
            guard let destination = promptSaveDestination(
                suggestedName: suggested,
                allowedContentType: .pdf
            ) else { return }

            runConversion { progress in
                try await PDFConverter.mergeImagesToPDF(
                    sourceURLs: sources,
                    destinationURL: destination,
                    progress: progress
                )
                return .singleFile(destination)
            }
        }
    }

    func startMultiPDFConversion() {
        guard case .multiPDF(let sources) = route else { return }
        let firstBase = sources.first?.deletingPathExtension().lastPathComponent ?? "Merged"
        let suggested = "\(firstBase) merged.pdf"
        guard let destination = promptSaveDestination(
            suggestedName: suggested,
            allowedContentType: .pdf
        ) else { return }

        runConversion { [options = self.options] progress in
            try await PDFConverter.mergePDFs(
                sourceURLs: sources,
                destinationURL: destination,
                compression: options.pdfCompression,
                options: options,
                progress: progress
            )
            return .singleFile(destination)
        }
    }

    // MARK: - Panels

    private func promptSaveDestination(
        suggestedName: String,
        allowedContentType: UTType?
    ) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if let allowedContentType {
            panel.allowedContentTypes = [allowedContentType]
        }
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func promptDirectory(message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = message
        return panel.runModal() == .OK ? panel.url : nil
    }

    // MARK: - Runner

    private func runConversion(
        _ work: @escaping @MainActor (@Sendable @escaping (Double) async -> Void) async throws -> ConversionResult
    ) {
        state = .running(0)
        currentTask?.cancel()
        currentTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let progress: @Sendable (Double) async -> Void = { [weak self] value in
                await MainActor.run {
                    guard let self else { return }
                    if self.state.isRunning {
                        self.state = .running(max(0, min(1, value)))
                    }
                }
            }
            do {
                let result = try await work(progress)
                self.state = .succeeded(result)
            } catch is CancellationError {
                self.state = .cancelled
            } catch let error as ConversionError {
                self.state = .failed(error.localizedDescription)
            } catch {
                self.state = .failed(error.localizedDescription)
            }
            self.currentTask = nil
        }
    }

    // MARK: - Reveal

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private extension SingleImageTarget {
    var utType: UTType {
        switch self {
        case .image(let f): return f.utType
        case .pdf: return .pdf
        }
    }

    var utTypeForSave: UTType? {
        utType
    }
}

private extension VideoFormat {
    var utTypeForSave: UTType? {
        switch self {
        case .mp4: return .mpeg4Movie
        case .mov: return .quickTimeMovie
        case .m4v: return UTType(filenameExtension: "m4v")
        }
    }
}
