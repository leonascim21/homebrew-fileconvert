import Foundation

enum AppRoute: Equatable {
    case landing
    case image(source: URL)
    case pdf(source: URL)
    case video(source: URL)
    case multiImage(sources: [URL])

    var isLanding: Bool {
        if case .landing = self { return true }
        return false
    }
}

enum MultiImageMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case convertEach
    case mergeIntoPDF

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .convertEach: return "Convert each file"
        case .mergeIntoPDF: return "Merge into one PDF"
        }
    }

    var symbol: String {
        switch self {
        case .convertEach: return "square.grid.2x2"
        case .mergeIntoPDF: return "doc.on.doc"
        }
    }
}

enum SingleImageTarget: Hashable, Identifiable, Sendable, CaseIterable {
    case image(ImageFormat)
    case pdf

    static var allCases: [SingleImageTarget] {
        ImageFormat.allCases.map { .image($0) } + [.pdf]
    }

    var id: String {
        switch self {
        case .image(let f): return "image.\(f.rawValue)"
        case .pdf: return "pdf"
        }
    }

    var displayName: String {
        switch self {
        case .image(let f): return f.displayName
        case .pdf: return "PDF"
        }
    }

    var fileExtension: String {
        switch self {
        case .image(let f): return f.fileExtension
        case .pdf: return "pdf"
        }
    }

    var isLossyImage: Bool {
        if case .image(let f) = self { return f.isLossy }
        return false
    }
}
