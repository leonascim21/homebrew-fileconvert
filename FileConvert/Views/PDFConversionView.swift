import SwiftUI

struct PDFConversionView: View {
    @Environment(AppViewModel.self) private var viewModel
    let source: URL

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(title: title, subtitle: source.lastPathComponent) {
            SourceFileCard(url: source)

            VStack(alignment: .leading, spacing: 10) {
                Text("Convert to")
                    .font(.headline)
                Picker("Target", selection: $bindable.pdfOutputTarget) {
                    ForEach(PDFOutputTarget.allCases) { target in
                        Label(target.displayName, systemImage: target.symbol).tag(target)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            switch viewModel.pdfOutputTarget {
            case .images:
                imagesControls
            case .pdf:
                pdfCompressControls
            }

            ActionFooter(
                actionLabel: actionLabel,
                actionSymbol: actionSymbol
            ) {
                viewModel.startPDFConversion()
            }
            .padding(.top, 4)
        }
    }

    private var title: String {
        switch viewModel.pdfOutputTarget {
        case .images: return "PDF → Images"
        case .pdf: return "Compress PDF"
        }
    }

    private var actionLabel: String {
        switch viewModel.pdfOutputTarget {
        case .images: return "Render & Save…"
        case .pdf: return "Compress & Save…"
        }
    }

    private var actionSymbol: String {
        switch viewModel.pdfOutputTarget {
        case .images: return "photo.stack"
        case .pdf: return "doc.zipper"
        }
    }

    @ViewBuilder
    private var imagesControls: some View {
        @Bindable var bindable = viewModel

        VStack(alignment: .leading, spacing: 10) {
            Text("Output image format")
                .font(.headline)
            Picker("Format", selection: $bindable.pdfOutputFormat) {
                ForEach(ImageFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 220, alignment: .leading)
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Compression")
                .font(.headline)

            Picker("Compression", selection: $bindable.options.imageCompression) {
                ForEach(CompressionMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(viewModel.options.imageCompression == .lossless
                 ? "Renders pages at the chosen DPI; lossy formats encoded at maximum quality."
                 : "Renders pages at the chosen DPI; lossy formats use the quality slider.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Resolution")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(viewModel.options.pdfDPI)) DPI")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $bindable.options.pdfDPI, in: 72...600, step: 12)
            }
            .padding(.top, 4)

            if viewModel.options.imageCompression == .lossy, viewModel.pdfOutputFormat.isLossy {
                qualitySlider(format: viewModel.pdfOutputFormat)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var pdfCompressControls: some View {
        @Bindable var bindable = viewModel

        VStack(alignment: .leading, spacing: 10) {
            Text("Compression")
                .font(.headline)

            Picker("Compression", selection: $bindable.options.pdfCompression) {
                ForEach(CompressionMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(viewModel.options.pdfCompression == .lossless
                 ? "Re-saves the PDF without rasterizing — preserves text and vectors exactly."
                 : "Rasterizes pages and re-encodes them as JPEG. Smaller files; text becomes images.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.options.pdfCompression == .lossy {
                lossyPDFControls
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var lossyPDFControls: some View {
        @Bindable var bindable = viewModel

        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Quality")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(viewModel.options.pdfCompressionQuality * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $bindable.options.pdfCompressionQuality, in: 0.1...1.0)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Resolution")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(viewModel.options.pdfCompressionDPI)) DPI")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $bindable.options.pdfCompressionDPI, in: 72...300, step: 12)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func qualitySlider(format: ImageFormat) -> some View {
        @Bindable var bindable = viewModel

        let binding: Binding<Double> = {
            switch format {
            case .jpeg: return $bindable.options.jpegQuality
            case .heic: return $bindable.options.heicQuality
            case .webp: return $bindable.options.webpQuality
            default: return .constant(1.0)
            }
        }()

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Quality")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(binding.wrappedValue * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: binding, in: 0.1...1.0)
        }
    }
}
