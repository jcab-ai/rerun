import AppKit
import RerunCore
import RerunUI
import SwiftUI

@main
struct RerunApp: App {
    @StateObject private var model = AppModel.live()

    init() {
        FontRegistry.registerBundledFonts()
        // Launched with `swift run` there's no app bundle; still show a Dock icon and menu bar.
        if Bundle.main.bundleIdentifier == nil {
            NSApplication.shared.setActivationPolicy(.regular)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear { NSApplication.shared.activate(ignoringOtherApps: true) }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: Tokens.Metrics.windowWidth, height: Tokens.Metrics.windowHeight)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            ProviderSettingsView()
                .environmentObject(model)
        }
    }
}
