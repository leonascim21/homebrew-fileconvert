import Foundation
import AVFoundation

struct ConversionOptions: Equatable, Sendable {
    var jpegQuality: Double = 0.9
    var heicQuality: Double = 0.85
    var webpQuality: Double = 0.85
    var pdfDPI: Double = 200
    var videoPreset: VideoPreset = .highest

    static let `default` = ConversionOptions()
}

enum VideoPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case passthrough
    case highest
    case p1080
    case p720
    case p480

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .passthrough: return "Passthrough (remux)"
        case .highest: return "Highest Quality"
        case .p1080: return "1080p"
        case .p720: return "720p"
        case .p480: return "480p"
        }
    }

    var avPresetName: String {
        switch self {
        case .passthrough: return AVAssetExportPresetPassthrough
        case .highest: return AVAssetExportPresetHighestQuality
        case .p1080: return AVAssetExportPreset1920x1080
        case .p720: return AVAssetExportPreset1280x720
        case .p480: return AVAssetExportPreset640x480
        }
    }
}
