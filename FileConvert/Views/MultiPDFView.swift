import SwiftUI

struct MultiPDFView: View {
    @Environment(AppViewModel.self) private var viewModel
    let sources: [URL]

    var body: some View {
        ConversionShell(
            title: "Merge PDFs",
            subtitle: "\(sources.count) files selected"
        ) {
            SourcePDFsCard(urls: sources)

            HStack(spacing: 10) {
                Image(systemName: "doc.on.doc.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                Text("All PDFs will be combined into a single PDF — pages preserved, in drop order.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
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
