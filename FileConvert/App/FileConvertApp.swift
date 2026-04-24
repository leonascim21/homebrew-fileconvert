import SwiftUI

@main
struct FileConvertApp: App {
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("FileConvert") {
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
