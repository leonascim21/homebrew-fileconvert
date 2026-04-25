import Foundation
import AVFoundation

enum VideoConverter {
    static func convert(
        sourceURL: URL,
        destinationURL: URL,
        format: VideoFormat,
        options: ConversionOptions,
        progress: @Sendable @escaping (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        let asset = AVURLAsset(url: sourceURL)
        let effectivePreset: VideoPreset = options.videoCompression == .lossless ? .passthrough : options.videoPreset
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: effectivePreset.avPresetName
        ) else {
            throw ConversionError.videoSessionFailed("preset unavailable")
        }

        let supported = await session.compatibleFileTypes
        guard supported.contains(format.fileType) else {
            throw ConversionError.unsupportedTarget(format.displayName)
        }

        let box = ExportSessionBox(session: session)

        let progressTask = Task {
            for await state in box.session.states(updateInterval: 0.1) {
                switch state {
                case .pending, .waiting:
                    await progress(0)
                case .exporting(let progressReport):
                    await progress(Double(progressReport.fractionCompleted))
                @unknown default:
                    break
                }
            }
        }

        do {
            try await withTaskCancellationHandler {
                try await box.session.export(to: destinationURL, as: format.fileType)
            } onCancel: {
                box.session.cancelExport()
            }
        } catch {
            progressTask.cancel()
            if Task.isCancelled {
                throw CancellationError()
            }
            throw ConversionError.videoSessionFailed(error.localizedDescription)
        }

        progressTask.cancel()
        await progress(1)
    }
}

private final class ExportSessionBox: @unchecked Sendable {
    let session: AVAssetExportSession
    init(session: AVAssetExportSession) { self.session = session }
}
