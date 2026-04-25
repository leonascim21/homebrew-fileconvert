import Foundation
import PDFKit
import AppKit
import ImageIO
import CoreGraphics

enum PDFConverter {
    static func imageToPDF(
        sourceURL: URL,
        destinationURL: URL,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw ConversionError.imageDecodeFailed(sourceURL)
        }

        let doc = PDFDocument()
        guard let page = PDFPage(image: image) else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }
        doc.insert(page, at: 0)

        if !doc.write(to: destinationURL) {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }
        await progress(1)
    }

    static func mergePDFs(
        sourceURLs: [URL],
        destinationURL: URL,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        guard !sourceURLs.isEmpty else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        let merged = PDFDocument()
        var totalPages = 0
        let docs: [PDFDocument] = try sourceURLs.map { url in
            guard let doc = PDFDocument(url: url) else {
                throw ConversionError.pdfLoadFailed(url)
            }
            totalPages += doc.pageCount
            return doc
        }

        guard totalPages > 0 else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        var written = 0
        for doc in docs {
            for index in 0..<doc.pageCount {
                try Task.checkCancellation()
                guard let page = doc.page(at: index) else {
                    throw ConversionError.pdfRenderFailed(written + 1)
                }
                merged.insert(page, at: merged.pageCount)
                written += 1
                await progress(Double(written) / Double(totalPages) * 0.95)
            }
        }

        if !merged.write(to: destinationURL) {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }
        await progress(1)
    }

    static func mergeImagesToPDF(
        sourceURLs: [URL],
        destinationURL: URL,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        guard !sourceURLs.isEmpty else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        let doc = PDFDocument()
        let total = Double(sourceURLs.count)
        for (index, url) in sourceURLs.enumerated() {
            try Task.checkCancellation()
            guard let image = NSImage(contentsOf: url) else {
                throw ConversionError.imageDecodeFailed(url)
            }
            guard let page = PDFPage(image: image) else {
                throw ConversionError.pdfWriteFailed(destinationURL)
            }
            doc.insert(page, at: doc.pageCount)
            await progress(Double(index + 1) / total * 0.95)
        }

        if !doc.write(to: destinationURL) {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }
        await progress(1)
    }

    static func pdfToImages(
        sourceURL: URL,
        destinationDirectory: URL,
        format: ImageFormat,
        options: ConversionOptions,
        progress: @Sendable (Double) async -> Void
    ) async throws -> [URL] {
        await progress(0)
        try Task.checkCancellation()

        guard let doc = PDFDocument(url: sourceURL) else {
            throw ConversionError.pdfLoadFailed(sourceURL)
        }

        let pageCount = doc.pageCount
        guard pageCount > 0 else {
            throw ConversionError.pdfLoadFailed(sourceURL)
        }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let dpi = options.pdfDPI
        let scale = dpi / 72.0
        let digits = max(3, String(pageCount).count)

        var results: [URL] = []
        for index in 0..<pageCount {
            try Task.checkCancellation()
            guard let page = doc.page(at: index) else {
                throw ConversionError.pdfRenderFailed(index + 1)
            }

            let bounds = page.bounds(for: .mediaBox)
            let pixelWidth = Int((bounds.width * scale).rounded())
            let pixelHeight = Int((bounds.height * scale).rounded())
            guard pixelWidth > 0, pixelHeight > 0 else {
                throw ConversionError.pdfRenderFailed(index + 1)
            }

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
                | CGBitmapInfo.byteOrder32Little.rawValue

            guard let ctx = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                throw ConversionError.pdfRenderFailed(index + 1)
            }

            ctx.setFillColor(CGColor.white)
            ctx.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.minX, y: -bounds.minY)
            page.draw(with: .mediaBox, to: ctx)

            guard let cgImage = ctx.makeImage() else {
                throw ConversionError.pdfRenderFailed(index + 1)
            }

            let pageIndexLabel = String(format: "%0\(digits)d", index + 1)
            let pageBaseName = "\(baseName)-page-\(pageIndexLabel)"
            let outputURL = OutputNamer.uniqueURL(
                in: destinationDirectory,
                baseName: pageBaseName,
                fileExtension: format.fileExtension
            )

            try writeCGImage(cgImage, to: outputURL, format: format, options: options)
            results.append(outputURL)
            await progress(Double(index + 1) / Double(pageCount))
        }

        return results
    }

    private static func writeCGImage(
        _ image: CGImage,
        to url: URL,
        format: ImageFormat,
        options: ConversionOptions
    ) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ConversionError.imageEncodeFailed(format.displayName)
        }

        var props: [String: Any] = [:]
        switch format {
        case .jpeg: props[kCGImageDestinationLossyCompressionQuality as String] = options.jpegQuality
        case .heic: props[kCGImageDestinationLossyCompressionQuality as String] = options.heicQuality
        case .webp: props[kCGImageDestinationLossyCompressionQuality as String] = options.webpQuality
        default: break
        }

        CGImageDestinationAddImage(destination, image, props as CFDictionary)

        if !CGImageDestinationFinalize(destination) {
            throw ConversionError.imageEncodeFailed("finalize failed for \(format.displayName)")
        }
    }
}
