import Foundation

enum OutputNamer {
    static func uniqueURL(in directory: URL, baseName: String, fileExtension: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent("\(baseName).\(fileExtension)")
        var index = 1
        while fm.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) (\(index)).\(fileExtension)")
            index += 1
        }
        return candidate
    }

    static func uniqueURL(in directory: URL, forSource source: URL, fileExtension: String) -> URL {
        let base = source.deletingPathExtension().lastPathComponent
        return uniqueURL(in: directory, baseName: base, fileExtension: fileExtension)
    }
}
