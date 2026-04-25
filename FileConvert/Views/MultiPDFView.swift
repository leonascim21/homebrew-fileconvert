import SwiftUI

struct MultiPDFView: View {
    @Environment(AppViewModel.self) private var viewModel
    let sources: [URL]

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(
            title: "Merge PDFs",
            subtitle: "\(sources.count) files selected"
        ) {
            SourcePDFsCard(urls: sources)

            HStack(spacing: 10) {
                Image(systemName: "doc.on.doc.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                Text("All PDFs will be combined into a single PDF — in drop order.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))

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

                Text(compressionFootnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.options.pdfCompression == .lossy {
                    lossyControls
                }
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))

            ActionFooter(
                actionLabel: "Merge \(sources.count) PDFs & Save…",
                actionSymbol: "doc.richtext.fill"
            ) {
                viewModel.startMultiPDFConversion()
            }
            .padding(.top, 4)
        }
    }

    private var compressionFootnote: String {
        switch viewModel.options.pdfCompression {
        case .off:
            return "Combines PDFs as-is — no re-encoding or compression applied."
        case .lossless:
            return "Preserves text, vectors, and original images exactly."
        case .lossy:
            return "Rasterizes pages and re-encodes them as JPEG. Smaller files; text becomes images."
        }
    }

    @ViewBuilder
    private var lossyControls: some View {
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
}

struct SourcePDFsCard: View {
    let urls: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "doc.richtext")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                Text("\(urls.count) PDFs")
                    .font(.headline)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(urls.prefix(12), id: \.self) { url in
                        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .help(url.lastPathComponent)
                    }
                    if urls.count > 12 {
                        Text("+\(urls.count - 12)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
