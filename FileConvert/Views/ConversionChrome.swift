import SwiftUI
import AppKit
import QuickLookThumbnailing

struct ConversionShell<Content: View>: View {
    @Environment(AppViewModel.self) private var viewModel
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content()
                }
                .padding(24)
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.reset()
            } label: {
                Label("Start Over", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.glass)
            .disabled(viewModel.state.isRunning)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.weight(.semibold))
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

struct SourceFileCard: View {
    let url: URL

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(url.pathExtension.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

struct SourceFilesCard: View {
    let urls: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                Text("\(urls.count) images")
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

struct ActionFooter: View {
    @Environment(AppViewModel.self) private var viewModel
    let actionLabel: String
    let actionSymbol: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            switch viewModel.state {
            case .running(let progress):
                runningCard(progress: progress)
            case .succeeded(let result):
                resultCard(result: result)
            case .failed(let message):
                errorCard(message: message)
            case .cancelled:
                cancelledCard
            case .idle:
                EmptyView()
            }

            HStack(spacing: 12) {
                if viewModel.state.isRunning {
                    Button(role: .destructive) {
                        viewModel.cancel()
                    } label: {
                        Label("Cancel", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                    .buttonStyle(.glass)
                } else {
                    Button(action: action) {
                        Label(actionLabel, systemImage: actionSymbol)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                    .buttonStyle(.glass)
                    .tint(.accentColor)
                }
            }
        }
    }

    private func runningCard(progress: Double) -> some View {
        HStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
            Text("\(Int(progress * 100))%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func resultCard(result: ConversionResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Done")
                    .font(.headline)
                Text(result.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if let reveal = result.revealTarget {
                Button {
                    viewModel.reveal(reveal)
                } label: {
                    Label("Show in Finder", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.glass)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .lineLimit(3)
            Spacer()
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var cancelledCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            Text("Cancelled")
                .font(.subheadline)
            Spacer()
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}
