import AppKit
import RerunCore
import SwiftUI

/// The ⌘, window: model API keys (Keychain), which model writes which kind of
/// scene, and building the world from Messages. The in-app "Contents"
/// settings page from the mockup comes in a later iteration.
public struct ProviderSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var keys: [LLMProviderID: String] = [:]
    @State private var savedNotice: LLMProviderID?
    @State private var access: MessagesLibrary.Access = .missing

    public init() {}

    public var body: some View {
        Form {
            Section {
                ForEach(LLMProviderID.cloud, id: \.self) { provider in
                    keyRow(provider)
                }
                HStack {
                    Text("On this Mac")
                    Spacer()
                    Text(OnDeviceModel.isAvailable ? "ready — no key needed" : OnDeviceModel.unavailableReason)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("API keys")
            } footer: {
                Text("Stored in your login Keychain. Only story prompts are sent to the provider you route a scene to — never whole threads.")
                    .foregroundStyle(.secondary)
            }

            Section {
                routeRow(title: "Everything else", route: model.settings.routing.fallback) { route in
                    model.updateSettings { $0.routing.fallback = route }
                }
                ForEach(MomentTag.allCases, id: \.self) { tag in
                    tagRouteRow(tag)
                }
            } header: {
                Text("Model routing")
            } footer: {
                Text("Each story turn is routed by its scene. If a provider has no key, the turn falls back to one that does.")
                    .foregroundStyle(.secondary)
            }

            Section {
                messagesRow
            } header: {
                Text("Messages")
            } footer: {
                Text("rerun copies chat.db to a private temporary folder and reads the copy. It never writes to Messages or sends anything.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 640)
        .onAppear {
            for provider in LLMProviderID.cloud {
                keys[provider] = model.secrets.apiKey(for: provider) ?? ""
            }
            access = model.messagesAccess
        }
    }

    // MARK: Keys

    private func keyRow(_ provider: LLMProviderID) -> some View {
        HStack {
            SecureField(provider.displayName, text: Binding(
                get: { keys[provider] ?? "" },
                set: { keys[provider] = $0; savedNotice = nil }
            ))
            Button(savedNotice == provider ? "Saved" : "Save") {
                do {
                    try model.secrets.setAPIKey(keys[provider], for: provider)
                    savedNotice = provider
                } catch {
                    model.lastError = "Couldn't save the key: \(error)"
                }
            }
            .disabled((keys[provider] ?? "") == (model.secrets.apiKey(for: provider) ?? ""))
        }
    }

    // MARK: Routing

    private func tagRouteRow(_ tag: MomentTag) -> some View {
        let override = model.settings.routing.byTag[tag]
        return HStack {
            Toggle(isOn: Binding(
                get: { override != nil },
                set: { on in
                    model.updateSettings { $0.routing.byTag[tag] = on ? $0.routing.fallback : nil }
                }
            )) {
                Text(tag.rawValue.capitalized)
            }
            .toggleStyle(.checkbox)
            .frame(width: 120, alignment: .leading)

            if let override {
                routeEditor(route: override) { route in
                    model.updateSettings { $0.routing.byTag[tag] = route }
                }
            } else {
                Text("uses “everything else”")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func routeRow(title: String, route: ModelRoute, onChange: @escaping (ModelRoute) -> Void) -> some View {
        HStack {
            Text(title).frame(width: 120, alignment: .leading)
            routeEditor(route: route, onChange: onChange)
        }
    }

    private func routeEditor(route: ModelRoute, onChange: @escaping (ModelRoute) -> Void) -> some View {
        HStack {
            Picker("", selection: Binding(get: { route.provider }, set: { onChange(ModelRoute(provider: $0)) })) {
                ForEach(LLMProviderID.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .labelsHidden()
            .frame(width: 170)
            TextField("model", text: Binding(get: { route.model }, set: { onChange(ModelRoute(provider: route.provider, model: $0)) }))
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    // MARK: Messages

    @ViewBuilder
    private var messagesRow: some View {
        switch access {
        case .readable:
            Label("rerun can read your Messages history.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .needsFullDiskAccess:
            VStack(alignment: .leading, spacing: 8) {
                Label("Full Disk Access is off.", systemImage: "lock.fill")
                Text("macOS only lets apps open the Messages library with Full Disk Access. Turn it on for rerun, then come back.")
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Open Privacy & Security") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                    }
                    Button("Check again") { access = model.messagesAccess }
                }
            }
        case .missing:
            Label("No Messages history found on this Mac.", systemImage: "questionmark.circle")
        }

        if let progress = model.buildProgress {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress.fraction)
                Text([progress.phase.rawValue, progress.detail].compactMap { $0 }.joined(separator: " · "))
                    .foregroundStyle(.secondary)
            }
        } else {
            Button(model.isSampleWorld ? "Build my world from Messages" : "Rescan Messages") {
                model.rescan()
            }
            .disabled(access != .readable)
        }
    }
}
