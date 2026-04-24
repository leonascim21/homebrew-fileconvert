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
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                throw ConversionError.imageDecodeFailed(sourceURL)
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

    private static func encoderProperties(for format: ImageFormat, options: ConversionOptions) -> [String: Any] {
        var props: [String: Any] = [:]
        let quality: Double?
        switch format {
        case .jpeg: quality = options.jpegQuality
        case .heic: quality = options.heicQuality
        case .webp: quality = options.webpQuality
        default: quality = nil
        }
        if let q = quality {
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

        switch format {
        case .jpeg: props[kCGImageDestinationLossyCompressionQuality as String] = options.jpegQuality
        case .heic: props[kCGImageDestinationLossyCompressionQuality as String] = options.heicQuality
        case .webp: props[kCGImageDestinationLossyCompressionQuality as String] = options.webpQuality
        default: break
        }

        return props
    }
}
