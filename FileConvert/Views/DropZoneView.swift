import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 56, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isTargeted ? Color.accentColor : Color.accentColor.opacity(0.85))

            VStack(spacing: 6) {
                Text(isTargeted ? "Release to open" : "Drop a file to convert")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Image, PDF, or video — or several images at once")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Button {
                viewModel.pickFiles()
            } label: {
                Label("Choose File…", systemImage: "folder")
                    .font(.headline)
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.glass)
            .tint(.accentColor)
            .controlSize(.large)
            .padding(.top, 4)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(
            isTargeted ? .regular.interactive().tint(.accentColor) : .regular,
            in: .rect(cornerRadius: 28)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.12),
                    style: StrokeStyle(lineWidth: 1.4, dash: [7, 5])
                )
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            viewModel.pickFiles()
        }
        .dropDestination(for: URL.self) { urls, _ in
            viewModel.handleDrop(urls: urls)
            return !urls.isEmpty
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.18)) {
                isTargeted = targeted
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}
