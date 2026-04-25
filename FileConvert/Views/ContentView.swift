import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            switch viewModel.route {
            case .landing:
                LandingView()
                    .transition(.opacity)
            case .image(let source):
                ImageConversionView(source: source)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .pdf(let source):
                PDFConversionView(source: source)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .video(let source):
                VideoConversionView(source: source)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .docx(let source):
                DocxConversionView(source: source)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .multiImage(let sources):
                MultiImageView(sources: sources)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .multiPDF(let sources):
                MultiPDFView(sources: sources)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.route)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("File Convert")
    }
}
