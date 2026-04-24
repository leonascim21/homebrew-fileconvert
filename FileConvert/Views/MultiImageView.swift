import SwiftUI

struct MultiImageView: View {
    @Environment(AppViewModel.self) private var viewModel
    let sources: [URL]

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(
            title: "Multiple images",
            subtitle: "\(sources.count) files selected"
        ) {
            SourceFilesCard(urls: sources)

            VStack(alignment: .leading, spacing: 10) {
                Text("What do you want to do?")
                    .font(.headline)

                Picker("Mode", selection: $bindable.multiImageMode) {
                    ForEach(MultiImageMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            switch viewModel.multiImageMode {
            case .convertEach:
                convertEachControls
            case .mergeIntoPDF:
                mergeControls
            }

            ActionFooter(
                actionLabel: actionLabel,
                actionSymbol: actionSymbol
            ) {
                viewModel.startMultiImageConversion()
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var convertEachControls: some View {
        @Bindable var bindable = viewModel

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Target format")
                    .font(.subheadline)
                Spacer()
                Picker("Format", selection: $bindable.multiImageFormat) {
                    ForEach(ImageFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 180)
            }

            if viewModel.multiImageFormat.isLossy {
                qualitySlider(format: viewModel.multiImageFormat)
            }

            Text("Files are saved to the folder you choose, preserving each original name.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var mergeControls: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.doc.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.accent)
            Text("All images will be combined into a single PDF — one page per image, in drop order.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
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

    private var actionLabel: String {
        switch viewModel.multiImageMode {
        case .convertEach: return "Convert \(sources.count) & Save…"
        case .mergeIntoPDF: return "Merge to PDF & Save…"
        }
    }

    private var actionSymbol: String {
        switch viewModel.multiImageMode {
        case .convertEach: return "square.stack.3d.up"
        case .mergeIntoPDF: return "doc.richtext.fill"
        }
    }
}
