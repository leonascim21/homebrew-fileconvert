import SwiftUI

struct ImageConversionView: View {
    @Environment(AppViewModel.self) private var viewModel
    let source: URL

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(title: "Convert image", subtitle: source.lastPathComponent) {
            SourceFileCard(url: source)

            VStack(alignment: .leading, spacing: 10) {
                Text("Convert to")
                    .font(.headline)
                Picker("Target", selection: $bindable.singleImageTarget) {
                    ForEach(SingleImageTarget.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 220, alignment: .leading)
            }

            compressionCard

            ActionFooter(
                actionLabel: "Convert & Save…",
                actionSymbol: "sparkles"
            ) {
                viewModel.startImageConversion()
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var compressionCard: some View {
        @Bindable var bindable = viewModel

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

            Text(footnote)
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.options.imageCompression == .lossy {
                if case .image(let format) = viewModel.singleImageTarget, format.isLossy {
                    qualitySlider(format: format)
                }
                maxEdgeSlider
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var footnote: String {
        if case .image(let format) = viewModel.singleImageTarget, format.isLossy {
            return viewModel.options.imageCompression == .lossless
                ? "Encodes \(format.displayName) at maximum quality."
                : "Reduces \(format.displayName) quality and (optionally) image dimensions."
        }
        return viewModel.options.imageCompression == .lossless
            ? "Preserves the original pixels exactly."
            : "Optionally downsamples image dimensions before encoding."
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

    @ViewBuilder
    private var maxEdgeSlider: some View {
        @Bindable var bindable = viewModel

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Max long edge")
                    .font(.subheadline)
                Spacer()
                Text(viewModel.options.imageMaxLongEdge == 0
                     ? "Original"
                     : "\(Int(viewModel.options.imageMaxLongEdge)) px")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $bindable.options.imageMaxLongEdge, in: 0...8000, step: 100)
        }
    }
}
