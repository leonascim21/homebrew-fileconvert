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
                Text("Quality preset")
                    .font(.headline)
                Picker("Preset", selection: $bindable.options.videoPreset) {
                    ForEach(VideoPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 260, alignment: .leading)

                Text(viewModel.options.videoPreset == .passthrough
                     ? "Fastest — remuxes without re-encoding when codecs match."
                     : "Re-encodes video and audio to the chosen target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
