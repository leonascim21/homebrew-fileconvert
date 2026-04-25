import Foundation
import UniformTypeIdentifiers
import AVFoundation

enum ImageFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    case jpeg
    case png
    case heic
    case tiff
    case gif
    case bmp
    case webp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .heic: return "HEIC"
        case .tiff: return "TIFF"
        case .gif: return "GIF"
        case .bmp: return "BMP"
        case .webp: return "WebP"
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .tiff: return "tiff"
        case .gif: return "gif"
        case .bmp: return "bmp"
        case .webp: return "webp"
        }
    }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .tiff: return .tiff
        case .gif: return .gif
        case .bmp: return .bmp
        case .webp: return UTType(filenameExtension: "webp") ?? UTType("org.webmproject.webp") ?? .image
        }
    }

    var isLossy: Bool {
        switch self {
        case .jpeg, .heic, .webp: return true
        default: return false
        }
    }
}

enum VideoFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    case mp4
    case mov
    case m4v

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mp4: return "MP4"
        case .mov: return "QuickTime (MOV)"
        case .m4v: return "M4V"
        }
    }

    var fileExtension: String { rawValue }

    var fileType: AVFileType {
        switch self {
        case .mp4: return .mp4
        case .mov: return .mov
        case .m4v: return .m4v
        }
    }
}

enum OutputFormat: Hashable, Identifiable, Sendable {
    case image(ImageFormat)
    case pdf
    case video(VideoFormat)

    var id: String {
        switch self {
        case .image(let f): return "image.\(f.rawValue)"
        case .pdf: return "pdf"
        case .video(let f): return "video.\(f.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .image(let f): return f.displayName
        case .pdf: return "PDF"
        case .video(let f): return f.displayName
        }
    }

    var fileExtension: String {
        switch self {
        case .image(let f): return f.fileExtension
        case .pdf: return "pdf"
        case .video(let f): return f.fileExtension
        }
    }

    var family: OutputFamily {
        switch self {
        case .image: return .image
        case .pdf: return .pdf
        case .video: return .video
        }
    }
}

enum OutputFamily: String, CaseIterable, Identifiable, Hashable, Sendable {
    case image, pdf, video, document
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .pdf: return "PDF"
        case .video: return "Video"
        case .document: return "Document"
        }
    }
    var symbol: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .video: return "film"
        case .document: return "doc.text"
        }
    }
}
