import Foundation
import UniformTypeIdentifiers

enum FormatDetector {
    static func detect(url: URL) -> UTType? {
        if let values = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let type = values.contentType {
            return type
        }
        return UTType(filenameExtension: url.pathExtension)
    }

    static func family(for type: UTType?) -> OutputFamily? {
        guard let type else { return nil }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return .video }
        if type.conforms(to: .image) { return .image }
        return nil
    }

    static func isSupported(url: URL) -> Bool {
        family(for: detect(url: url)) != nil
    }
}
