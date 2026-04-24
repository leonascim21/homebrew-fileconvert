import SwiftUI

struct PDFConversionView: View {
    @Environment(AppViewModel.self) private var viewModel
    let source: URL

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(title: "PDF → Images", subtitle: source.lastPathComponent) {
            SourceFileCard(url: source)

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
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))

            if viewModel.pdfOutputFormat.isLossy {
                qualitySlider(format: viewModel.pdfOutputFormat)
            }

            ActionFooter(
                actionLabel: "Render & Save…",
                actionSymbol: "photo.stack"
            ) {
                viewModel.startPDFConversion()
            }
            .padding(.top, 4)
        }
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
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}
