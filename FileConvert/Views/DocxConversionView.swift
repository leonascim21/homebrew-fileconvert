import SwiftUI

struct DocxConversionView: View {
    @Environment(AppViewModel.self) private var viewModel
    let source: URL

    var body: some View {
        ConversionShell(title: "Word → PDF", subtitle: source.lastPathComponent) {
            SourceFileCard(url: source)

            HStack(spacing: 10) {
                Image(systemName: "text.book.closed.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                Text("Renders the document's text and inline formatting to a paginated PDF. Complex layouts (tables, headers, embedded objects) may simplify.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))

            ActionFooter(
                actionLabel: "Convert to PDF & Save…",
                actionSymbol: "doc.richtext.fill"
            ) {
                viewModel.startDocxConversion()
            }
            .padding(.top, 4)
        }
    }
}
