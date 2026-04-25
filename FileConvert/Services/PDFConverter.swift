import Foundation
import PDFKit
import AppKit
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

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
        compression: CompressionMode,
        options: ConversionOptions,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        guard !sourceURLs.isEmpty else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        if compression == .off, sourceURLs.count == 1, let src = sourceURLs.first {
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationURL.path) {
                try? fm.removeItem(at: destinationURL)
            }
            try fm.copyItem(at: src, to: destinationURL)
            await progress(1)
            return
        }

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

        switch compression {
        case .off, .lossless:
            let merged = PDFDocument()
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

        case .lossy:
            try await writeLossyPDF(
                docs: docs,
                totalPages: totalPages,
                destinationURL: destinationURL,
                quality: options.pdfCompressionQuality,
                dpi: options.pdfCompressionDPI,
                progress: progress
            )
        }
    }

    private static func writeLossyPDF(
        docs: [PDFDocument],
        totalPages: Int,
        destinationURL: URL,
        quality: Double,
        dpi: Double,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        guard let firstDoc = docs.first(where: { $0.pageCount > 0 }),
              let firstPage = firstDoc.page(at: 0) else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }
        var initialBox = CGRect(origin: .zero, size: renderedSize(for: firstPage))

        guard let pdfCtx = CGContext(destinationURL as CFURL, mediaBox: &initialBox, nil) else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        let scale = dpi / 72.0
        var written = 0

        for doc in docs {
            for index in 0..<doc.pageCount {
                try Task.checkCancellation()
                guard let page = doc.page(at: index) else {
                    pdfCtx.closePDF()
                    throw ConversionError.pdfRenderFailed(written + 1)
                }

                let renderedRect = CGRect(origin: .zero, size: renderedSize(for: page))
                let pixelWidth = Int((renderedRect.width * scale).rounded())
                let pixelHeight = Int((renderedRect.height * scale).rounded())
                guard pixelWidth > 0, pixelHeight > 0 else {
                    pdfCtx.closePDF()
                    throw ConversionError.pdfRenderFailed(written + 1)
                }

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue

                guard let renderCtx = CGContext(
                    data: nil,
                    width: pixelWidth,
                    height: pixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) else {
                    pdfCtx.closePDF()
                    throw ConversionError.pdfRenderFailed(written + 1)
                }

                renderCtx.setFillColor(CGColor.white)
                renderCtx.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
                renderCtx.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: renderCtx)

                guard let rendered = renderCtx.makeImage() else {
                    pdfCtx.closePDF()
                    throw ConversionError.pdfRenderFailed(written + 1)
                }

                let jpegData = NSMutableData()
                guard let jpegDest = CGImageDestinationCreateWithData(
                    jpegData, UTType.jpeg.identifier as CFString, 1, nil
                ) else {
                    pdfCtx.closePDF()
                    throw ConversionError.imageEncodeFailed("JPEG")
                }
                let props: [String: Any] = [
                    kCGImageDestinationLossyCompressionQuality as String: quality
                ]
                CGImageDestinationAddImage(jpegDest, rendered, props as CFDictionary)
                guard CGImageDestinationFinalize(jpegDest) else {
                    pdfCtx.closePDF()
                    throw ConversionError.imageEncodeFailed("JPEG")
                }
                guard let jpegSource = CGImageSourceCreateWithData(jpegData, nil),
                      let jpegImage = CGImageSourceCreateImageAtIndex(jpegSource, 0, nil) else {
                    pdfCtx.closePDF()
                    throw ConversionError.imageEncodeFailed("JPEG")
                }

                var pageBox = renderedRect
                let boxData = Data(bytes: &pageBox, count: MemoryLayout<CGRect>.size)
                let pageInfo: [String: Any] = [
                    kCGPDFContextMediaBox as String: boxData
                ]
                pdfCtx.beginPDFPage(pageInfo as CFDictionary)
                pdfCtx.draw(jpegImage, in: renderedRect)
                pdfCtx.endPDFPage()

                written += 1
                await progress(Double(written) / Double(totalPages) * 0.95)
            }
        }

        pdfCtx.closePDF()
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

            let renderedSize = renderedSize(for: page)
            let pixelWidth = Int((renderedSize.width * scale).rounded())
            let pixelHeight = Int((renderedSize.height * scale).rounded())
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

    private static func renderedSize(for page: PDFPage) -> CGSize {
        let bounds = page.bounds(for: .mediaBox)
        let isQuarterTurn = (abs(page.rotation) % 180) != 0
        return isQuarterTurn
            ? CGSize(width: bounds.height, height: bounds.width)
            : bounds.size
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
