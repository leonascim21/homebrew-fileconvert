import Foundation
import UniformTypeIdentifiers

enum FormatDetector {
    private static let docxType = UTType("org.openxmlformats.wordprocessingml.document")
    private static let docType = UTType("com.microsoft.word.doc")

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
        if let docx = docxType, type.conforms(to: docx) { return .document }
        if let doc = docType, type.conforms(to: doc) { return .document }
        return nil
    }

    static func isSupported(url: URL) -> Bool {
        family(for: detect(url: url)) != nil
    }
}
