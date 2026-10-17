import Foundation
import RerunCore
import SwiftUI

/// The sidebar's sections, in mockup order.
public enum Screen: String, CaseIterable, Identifiable {
    case map, people, moments, notes, settings

    public var id: String { rawValue }

    public var number: String { String(format: "%02d", (Screen.allCases.firstIndex(of: self) ?? 0) + 1) }

    public var label: String {
        switch self {
        case .map: "World map"
        case .people: "People"
        case .moments: "Moments"
        case .notes: "Context notes"
        case .settings: "Settings"
        }
    }

    /// The nav sticker's color.
    public var color: PersonColor {
        switch self {
        case .map: .coral
        case .people: .blue
        case .moments: .sun
        case .notes: .grape
        case .settings: .leaf
        }
    }
}

/// App state: the world loaded from the local store (or the sample world
/// before the first scan), navigation, and world (re)building.
@MainActor
public final class AppModel: ObservableObject {
    @Published public private(set) var people: [Person] = []
    @Published public private(set) var moments: [Moment] = []
    @Published public private(set) var map = WorldMap(nodes: [])
    @Published public private(set) var settings = AppSettings()
    @Published public private(set) var voices: [String: VoiceProfile] = [:]
    /// True while showing the built-in sample world instead of the user's own.
    @Published public private(set) var isSampleWorld = false

    @Published public var screen: Screen = .map
    @Published public var openMomentID: String?
    /// nil shows everyone.
    @Published public var personFilter: String?

    @Published public private(set) var buildProgress: WorldBuildProgress?
    @Published public var lastError: String?
    private var isBuilding = false

    let store: RecordStore?
    public let secrets: SecretStore

    public init(store: RecordStore?, secrets: SecretStore) {
        self.store = store
        self.secrets = secrets
        reload()
    }

    /// The real app: the store in Application Support, keys in the Keychain.
    public static func live() -> AppModel {
        let store: RecordStore?
        do {
            store = try RecordStore(url: RecordStore.defaultURL())
        } catch {
            NSLog("rerun: couldn't open the local store: \(error)")
            store = nil
        }
        return AppModel(store: store, secrets: KeychainSecretStore())
    }

    /// The sample world, for previews.
    public static func sample() -> AppModel {
        AppModel(store: nil, secrets: InMemorySecretStore())
    }

    public func reload() {
        do {
            if let store, let map = try store.get(WorldMap.self, id: WorldMap.singletonID) {
                self.map = map
                people = try store.all(Person.self)
                moments = try store.all(Moment.self)
                voices = Dictionary(try store.all(VoiceProfile.self).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
                settings = try store.get(AppSettings.self, id: AppSettings.singletonID) ?? AppSettings()
                isSampleWorld = false
                return
            }
            settings = try store?.get(AppSettings.self, id: AppSettings.singletonID) ?? AppSettings()
        } catch {
            lastError = "Couldn't read your world: \(error)"
        }
        loadSampleWorld()
    }

    private func loadSampleWorld() {
        people = DemoWorld.people
        moments = DemoWorld.moments
        map = DemoWorld.map
        voices = [:]
        // Keep the user's own settings (routing etc.), but show the sample's player.
        settings.player = DemoWorld.player
        isSampleWorld = true
    }

    // MARK: Lookups

    public func person(_ id: String) -> Person? { people.first { $0.id == id } }
    public func moment(_ id: String) -> Moment? { moments.first { $0.id == id } }

    /// People in the world, in stored order (biggest threads first after a scan).
    public var includedPeople: [Person] { people.filter(\.included) }

    /// The three biggest threads, shown as filter chips, in sidebar order.
    public var chipPeople: [Person] {
        let top = Set(includedPeople.sorted { $0.messageCount > $1.messageCount }.prefix(3).map(\.id))
        return includedPeople.filter { top.contains($0.id) }
    }

    public var featuredMomentID: String? {
        moments.filter { $0.lastPlayedAt != nil }.max { $0.lastPlayedAt! < $1.lastPlayedAt! }?.id
    }

    public var windowTitle: String {
        if let id = openMomentID, let moment = moment(id) { return "rerun — \(moment.title)" }
        return "rerun — \(screen.label)"
    }

    public func isDimmed(_ moment: Moment) -> Bool {
        guard let filter = personFilter else { return false }
        return !moment.personIDs.contains(filter)
    }

    // MARK: Settings

    public func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&settings)
        do {
            try store?.save(settings)
        } catch {
            lastError = "Couldn't save settings: \(error)"
        }
    }

    // MARK: Building the world

    public var messagesAccess: MessagesLibrary.Access { MessagesLibrary.access() }

    /// Scans Messages and replaces the world. Progress is published as it goes.
    public func rebuildWorld() async {
        guard let store, !isBuilding else { return }
        isBuilding = true
        buildProgress = WorldBuildProgress(phase: .copying, fraction: 0)
        lastError = nil

        let names = SystemContactNames()
        await names.load()
        let result = await Task.detached(priority: .userInitiated) { [weak self] () -> Result<WorldMap, Error> in
            Result {
                try WorldBuilder(store: store, names: names).build { progress in
                    Task { @MainActor in
                        // Updates can land after the build has finished; drop those.
                        if self?.isBuilding == true { self?.buildProgress = progress }
                    }
                }
            }
        }.value

        isBuilding = false
        buildProgress = nil
        switch result {
        case .success:
            reload()
        case .failure(let error):
            lastError = "Couldn't build your world: \(error)"
        }
    }
}
