import Foundation

enum ConversionError: LocalizedError {
    case unsupportedSource(URL)
    case unsupportedTarget(String)
    case imageDecodeFailed(URL)
    case imageEncodeFailed(String)
    case pdfLoadFailed(URL)
    case pdfWriteFailed(URL)
    case pdfRenderFailed(Int)
    case documentLoadFailed(URL)
    case videoSessionFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSource(let url):
            return "Unsupported source: \(url.lastPathComponent)"
        case .unsupportedTarget(let name):
            return "Unsupported target format: \(name)"
        case .imageDecodeFailed(let url):
            return "Could not decode image \(url.lastPathComponent)"
        case .imageEncodeFailed(let reason):
            return "Image encode failed: \(reason)"
        case .pdfLoadFailed(let url):
            return "Could not open PDF \(url.lastPathComponent)"
        case .pdfWriteFailed(let url):
            return "Could not write PDF to \(url.lastPathComponent)"
        case .pdfRenderFailed(let page):
            return "Could not render PDF page \(page)"
        case .documentLoadFailed(let url):
            return "Could not read document \(url.lastPathComponent)"
        case .videoSessionFailed(let reason):
            return "Video export failed: \(reason)"
        case .unknown(let reason):
            return reason
        }
    }
}
