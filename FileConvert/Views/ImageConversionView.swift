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

            if case .image(let format) = viewModel.singleImageTarget, format.isLossy {
                qualitySlider(format: format)
            }

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
