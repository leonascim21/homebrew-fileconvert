import Foundation
import AppKit
import CoreGraphics

@MainActor
enum DocumentConverter {
    static func docxToPDF(
        sourceURL: URL,
        destinationURL: URL,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        let attr = try loadAttributedString(from: sourceURL)
        try Task.checkCancellation()
        await progress(0.2)

        try renderToPDF(attr, destinationURL: destinationURL)
        await progress(1)
    }

    private static func loadAttributedString(from url: URL) throws -> NSAttributedString {
        let candidates: [NSAttributedString.DocumentType] = [
            .officeOpenXML,
            .docFormat,
            .rtf,
            .plain
        ]
        for type in candidates {
            if let attr = try? NSAttributedString(
                url: url,
                options: [.documentType: type],
                documentAttributes: nil
            ) {
                return attr
            }
        }
        if let attr = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            return attr
        }
        throw ConversionError.documentLoadFailed(url)
    }

    private static func renderToPDF(_ attr: NSAttributedString, destinationURL: URL) throws {
        let pageSize = CGSize(width: 612, height: 792)
        let margin: CGFloat = 54
        let contentSize = CGSize(
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let ctx = CGContext(destinationURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ConversionError.pdfWriteFailed(destinationURL)
        }

        let storage = NSTextStorage(attributedString: attr)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        var safety = 0
        var lastEnd = 0
        while true {
            try Task.checkCancellation()
            let container = NSTextContainer(size: contentSize)
            container.lineFragmentPadding = 0
            layoutManager.addTextContainer(container)
            let range = layoutManager.glyphRange(for: container)
            if range.length == 0 { break }

            ctx.beginPDFPage(nil)
            ctx.saveGState()
            ctx.translateBy(x: margin, y: pageSize.height - margin)
            ctx.scaleBy(x: 1, y: -1)

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
            layoutManager.drawBackground(forGlyphRange: range, at: .zero)
            layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)
            NSGraphicsContext.restoreGraphicsState()

            ctx.restoreGState()
            ctx.endPDFPage()

            let end = NSMaxRange(range)
            if end >= layoutManager.numberOfGlyphs || end == lastEnd { break }
            lastEnd = end
            safety += 1
            if safety > 5000 { break }
        }

        ctx.closePDF()
    }
}
