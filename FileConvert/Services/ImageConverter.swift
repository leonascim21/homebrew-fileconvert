import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

enum ImageConverter {
    static func convert(
        sourceURL: URL,
        to destinationURL: URL,
        format: ImageFormat,
        options: ConversionOptions,
        progress: @Sendable (Double) async -> Void
    ) async throws {
        await progress(0)
        try Task.checkCancellation()

        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw ConversionError.imageDecodeFailed(sourceURL)
        }

        let sourceFrameCount = CGImageSourceGetCount(source)
        let supportsMultiFrame = Self.supportsMultiFrame(format)
        let frameCount = supportsMultiFrame ? sourceFrameCount : 1
        let downsamplePixels = downsampleMaxPixels(options: options)

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            format.utType.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw ConversionError.imageEncodeFailed("destination \(format.displayName) unavailable")
        }

        let encoderProps = encoderProperties(for: format, options: options)
        if !encoderProps.isEmpty {
            CGImageDestinationSetProperties(destination, encoderProps as CFDictionary)
        }

        for index in 0..<frameCount {
            try Task.checkCancellation()
            let image: CGImage
            if let downsamplePixels {
                let opts: [String: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways as String: true,
                    kCGImageSourceCreateThumbnailWithTransform as String: true,
                    kCGImageSourceShouldCacheImmediately as String: true,
                    kCGImageSourceThumbnailMaxPixelSize as String: downsamplePixels
                ]
                guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, index, opts as CFDictionary) else {
                    throw ConversionError.imageDecodeFailed(sourceURL)
                }
                image = thumb
            } else {
                guard let full = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                    throw ConversionError.imageDecodeFailed(sourceURL)
                }
                image = full
            }
            let frameProps = frameProperties(
                source: source,
                index: index,
                format: format,
                options: options
            )
            CGImageDestinationAddImage(destination, image, frameProps as CFDictionary)
            await progress(Double(index + 1) / Double(frameCount))
        }

        if !CGImageDestinationFinalize(destination) {
            throw ConversionError.imageEncodeFailed("finalize failed for \(format.displayName)")
        }

        await progress(1)
    }

    static func isEncodingAvailable(for format: ImageFormat) -> Bool {
        guard let supported = CGImageDestinationCopyTypeIdentifiers() as? [String] else { return false }
        return supported.contains(format.utType.identifier)
    }

    private static func supportsMultiFrame(_ format: ImageFormat) -> Bool {
        switch format {
        case .gif, .heic, .tiff, .webp: return true
        case .jpeg, .png, .bmp: return false
        }
    }

    private static func effectiveQuality(for format: ImageFormat, options: ConversionOptions) -> Double? {
        let raw: Double?
        switch format {
        case .jpeg: raw = options.jpegQuality
        case .heic: raw = options.heicQuality
        case .webp: raw = options.webpQuality
        default: raw = nil
        }
        guard let raw else { return nil }
        return options.imageCompression == .lossy ? raw : 1.0
    }

    private static func downsampleMaxPixels(options: ConversionOptions) -> Int? {
        guard options.imageCompression == .lossy else { return nil }
        let edge = options.imageMaxLongEdge
        guard edge > 0 else { return nil }
        return Int(edge.rounded())
    }

    private static func encoderProperties(for format: ImageFormat, options: ConversionOptions) -> [String: Any] {
        var props: [String: Any] = [:]
        if let q = effectiveQuality(for: format, options: options) {
            props[kCGImageDestinationLossyCompressionQuality as String] = q
        }
        return props
    }

    private static func frameProperties(
        source: CGImageSource,
        index: Int,
        format: ImageFormat,
        options: ConversionOptions
    ) -> [String: Any] {
        var props: [String: Any] = [:]

        if let existing = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any] {
            if let orientation = existing[kCGImagePropertyOrientation as String] {
                props[kCGImagePropertyOrientation as String] = orientation
            }
            if format == .gif,
               let gif = existing[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                props[kCGImagePropertyGIFDictionary as String] = gif
            }
            if format == .heic,
               let heic = existing[kCGImagePropertyHEICSDictionary as String] as? [String: Any] {
                props[kCGImagePropertyHEICSDictionary as String] = heic
            }
        }

        if let q = effectiveQuality(for: format, options: options) {
            props[kCGImageDestinationLossyCompressionQuality as String] = q
        }

        return props
    }
}
