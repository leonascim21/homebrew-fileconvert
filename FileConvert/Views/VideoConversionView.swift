import SwiftUI

struct VideoConversionView: View {
    @Environment(AppViewModel.self) private var viewModel
    let source: URL

    var body: some View {
        @Bindable var bindable = viewModel

        ConversionShell(title: "Convert video", subtitle: source.lastPathComponent) {
            SourceFileCard(url: source)

            VStack(alignment: .leading, spacing: 10) {
                Text("Target container")
                    .font(.headline)
                Picker("Format", selection: $bindable.videoTarget) {
                    ForEach(VideoFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Compression")
                    .font(.headline)

                Picker("Compression", selection: $bindable.options.videoCompression) {
                    ForEach(CompressionMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(viewModel.options.videoCompression == .lossless
                     ? "Remuxes without re-encoding — fastest, no quality loss when codecs match."
                     : "Re-encodes video and audio at the chosen preset.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.options.videoCompression == .lossy {
                    HStack {
                        Text("Preset")
                            .font(.subheadline)
                        Spacer()
                        Picker("Preset", selection: $bindable.options.videoPreset) {
                            ForEach(VideoPreset.allCases.filter { $0 != .passthrough }) { preset in
                                Text(preset.displayName).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: 220)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))

            ActionFooter(
                actionLabel: "Convert & Save…",
                actionSymbol: "film.stack"
            ) {
                viewModel.startVideoConversion()
            }
            .padding(.top, 4)
        }
    }
}
