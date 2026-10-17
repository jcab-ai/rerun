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
            AppIcon.applyForDevelopmentBuild()
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
            WorldCommands(model: model)
        }

        Settings {
            ProviderSettingsView()
                .environmentObject(model)
        }
    }
}

/// The "World" menu.
struct WorldCommands: Commands {
    @ObservedObject var model: AppModel

    var body: some Commands {
        CommandMenu("World") {
            Button("Play Last Moment") {
                if let id = model.featuredMomentID, let moment = model.moment(id) { model.play(moment) }
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(model.featuredMomentID == nil || model.onboarding != nil)

            Button("Back to the Map") {
                model.stopPlaying()
                model.go(to: .map)
            }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(model.onboarding != nil)

            Divider()

            Button(model.isSampleWorld ? "Build My World from Messages…" : "Rescan Messages") {
                if model.isSampleWorld { model.onboarding = .privacy } else { model.rescan() }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(model.onboarding != nil)

            Button("Choose People…") { model.requestMessagesAccess() }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(model.isSampleWorld || model.onboarding != nil)
        }
    }
}
