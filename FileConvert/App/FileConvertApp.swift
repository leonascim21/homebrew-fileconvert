import SwiftUI
import AppKit

@main
struct FileConvertApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = AppViewModel.shared

    var body: some Scene {
        Window("File Convert", id: "main") {
            ContentView()
                .environment(viewModel)
                .frame(minWidth: 680, minHeight: 520)
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .newItem) {
                Button("Open…") { viewModel.pickFiles() }
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        AppViewModel.shared.handleDrop(urls: urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
