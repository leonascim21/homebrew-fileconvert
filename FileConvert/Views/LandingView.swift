import SwiftUI

struct LandingView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            DropZoneView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)

            if case .failed(let message) = viewModel.state {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
    }
}
