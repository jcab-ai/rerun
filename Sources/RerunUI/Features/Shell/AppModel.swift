import AppKit
import Foundation
import RerunCore
import SwiftUI
import UserNotifications

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

    public var shortcut: KeyEquivalent {
        KeyEquivalent(Character(String((Screen.allCases.firstIndex(of: self) ?? 0) + 1)))
    }
}

/// The setup flow before there's a world.
public enum OnboardingStep: Equatable {
    case welcome
    case privacy
    /// Full Disk Access is off.
    case locked
    case choosePeople
    case building
    /// Messages opened, but there was nobody in it.
    case noConversations
}

/// App state: the world (from the local store, or the sample world before
/// the first scan), navigation, onboarding, play sessions and notes.
@MainActor
public final class AppModel: ObservableObject {
    // The world
    @Published public private(set) var people: [Person] = []
    @Published public private(set) var moments: [Moment] = []
    @Published public private(set) var map = WorldMap(nodes: [])
    @Published public private(set) var settings = AppSettings()
    @Published public private(set) var voices: [String: VoiceProfile] = [:]
    @Published public private(set) var notes: [ContextNote] = []
    /// True while showing the built-in sample world instead of the user's own.
    @Published public private(set) var isSampleWorld = false

    // Navigation
    @Published public var onboarding: OnboardingStep?
    @Published public var screen: Screen = .map
    @Published public var openMomentID: String?
    /// nil shows everyone on the map.
    @Published public var personFilter: String?
    /// The storyline being viewed on the People screen; nil shows everyone.
    @Published public var storylinePersonID: String?
    /// Whose notes the Context notes screen is editing.
    @Published public var notesPersonID: String?
    /// A moment to pre-pin a new note to.
    @Published public var notesMomentID: String?
    @Published public private(set) var playSession: PlaySession?

    // Scanning
    @Published public private(set) var buildProgress: WorldBuildProgress?
    @Published public private(set) var candidates: [Person] = []
    @Published public var lastError: String?
    private var isBuilding = false

    let store: RecordStore?
    public let secrets: SecretStore
    let storyEngine: StoryEngine
    let scripted = ScriptedStoryTeller(stories: DemoStories.all)

    public init(store: RecordStore?, secrets: SecretStore, startOnboarding: Bool = false) {
        self.store = store
        self.secrets = secrets
        self.storyEngine = StoryEngine(secrets: secrets)
        reload()
        if startOnboarding && !settings.hasCompletedOnboarding {
            onboarding = .welcome
        }
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
        return AppModel(store: store, secrets: KeychainSecretStore(), startOnboarding: true)
    }

    /// The sample world, for previews and snapshots.
    public static func sample() -> AppModel {
        AppModel(store: nil, secrets: InMemorySecretStore())
    }

    public func reload() {
        do {
            let stored = try store?.get(AppSettings.self, id: AppSettings.singletonID)
            if let store, let map = try store.get(WorldMap.self, id: WorldMap.singletonID) {
                self.map = map
                people = try store.all(Person.self)
                moments = try store.all(Moment.self)
                voices = Dictionary(try store.all(VoiceProfile.self).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
                notes = try store.all(ContextNote.self)
                settings = stored ?? AppSettings(player: Self.defaultPlayer, hasCompletedOnboarding: true)
                isSampleWorld = false
                return
            }
            loadSampleWorld(keeping: stored)
        } catch {
            lastError = "Couldn't read your world: \(error)"
            loadSampleWorld(keeping: nil)
        }
    }

    /// Shows the sample world. `settings` stay yours (they're what gets saved);
    /// only previews without a store borrow the sample's settings too.
    private func loadSampleWorld(keeping stored: AppSettings?) {
        people = DemoWorld.people
        moments = DemoWorld.moments
        map = DemoWorld.map
        voices = Dictionary(DemoWorld.voices.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        notes = DemoWorld.notes
        settings = stored ?? (store == nil ? DemoWorld.settings() : AppSettings(player: Self.defaultPlayer))
        isSampleWorld = true
    }

    /// Your first name from your Mac account, for the "you" node.
    static var defaultPlayer: PlayerProfile {
        let first = NSFullUserName().split(separator: " ").first.map(String.init) ?? ""
        return PlayerProfile(name: first.isEmpty ? "you" : first)
    }

    /// Who's at the center of the world on screen.
    public var player: PlayerProfile { isSampleWorld ? DemoWorld.player : settings.player }

    // MARK: Lookups

    public func person(_ id: String) -> Person? { people.first { $0.id == id } }
    public func moment(_ id: String) -> Moment? { moments.first { $0.id == id } }
    public func voice(_ personID: String) -> VoiceProfile? { voices[personID] }

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

    public func moments(with personID: String) -> [Moment] {
        moments.filter { $0.personIDs.contains(personID) }.sorted { $0.date < $1.date }
    }

    public func notes(for subject: ContextNote.Subject) -> [ContextNote] {
        notes.filter { $0.subject == subject }.sorted { $0.createdAt < $1.createdAt }
    }

    /// Notes about a person, plus notes pinned to any of their moments.
    public func notes(aboutPerson personID: String) -> [ContextNote] {
        let theirMoments = Set(moments(with: personID).map(\.id))
        return notes.filter { note in
            switch note.subject {
            case .person(let id): id == personID
            case .moment(let id): theirMoments.contains(id)
            }
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    public var windowTitle: String {
        if let onboarding {
            return onboarding == .welcome ? "Welcome to rerun" : "Set up rerun"
        }
        if let session = playSession {
            let short = session.moment.title.split(separator: ":").first.map(String.init) ?? session.moment.title
            return "rerun — Playing: \(short)"
        }
        if let id = openMomentID, let moment = moment(id) { return "rerun — \(moment.title)" }
        switch screen {
        case .people:
            if let id = storylinePersonID, let person = person(id) { return "rerun — People · \(person.displayName)" }
        case .notes:
            if let id = notesPersonID ?? includedPeople.first?.id, let person = person(id) { return "rerun — Context notes · \(person.displayName)" }
        default:
            break
        }
        return "rerun — \(screen.label)"
    }

    public func isDimmed(_ moment: Moment) -> Bool {
        guard let filter = personFilter else { return false }
        return !moment.personIDs.contains(filter)
    }

    // MARK: Navigation

    public func go(to screen: Screen) {
        openMomentID = nil
        if screen == .people && self.screen == .people { storylinePersonID = nil }
        self.screen = screen
    }

    public func openStoryline(_ personID: String) {
        openMomentID = nil
        storylinePersonID = personID
        screen = .people
    }

    public func openNotes(personID: String, momentID: String? = nil) {
        openMomentID = nil
        notesPersonID = personID
        notesMomentID = momentID
        screen = .notes
    }

    // MARK: Playing

    /// Whether `moment` can be played right now (a script, or a configured model).
    public func canPlay(_ moment: Moment) -> Bool {
        scripted.canTell(moment.id) || storyEngine.canTell(with: settings)
    }

    public var onDeviceAvailable: Bool { OnDeviceModel.isAvailable }

    public func play(_ moment: Moment) {
        let cast = moment.personIDs.compactMap(person).map { CastMember(person: $0, voice: voices[$0.id]) }
        var storySettings = settings
        storySettings.player = player
        let context = StoryContext(
            moment: moment,
            cast: cast,
            notes: notes.relevant(to: moment),
            settings: storySettings,
            excerpt: (try? excerpt(for: moment)) ?? []
        )
        let teller = LayeredStoryTeller(scripted: scripted, engine: storyEngine, settings: settings)
        let chapters = scripted.chapterCount(for: moment.id) ?? moment.chapterCount
        playSession = PlaySession(moment: moment, context: context, chapterCount: chapters, teller: teller) { [weak self] run in
            self?.finish(run)
        }
        openMomentID = nil
        playSession?.start()
    }

    /// Shows a prepared session (snapshots and previews).
    func present(_ session: PlaySession) {
        playSession = session
    }

    public func stopPlaying() {
        playSession?.cancel()
        playSession = nil
    }

    /// Re-reads the moment's real texts from a fresh Messages snapshot.
    private func excerpt(for moment: Moment) throws -> [ChatMessage] {
        guard !isSampleWorld, settings.shareMomentExcerpt, let source = moment.source,
              MessagesLibrary.access() == .readable else { return [] }
        let reader = ChatDatabaseReader(snapshot: try MessagesSnapshot())
        return try reader.messages(inChat: source.chatID).filter {
            (source.firstMessageRowID...source.lastMessageRowID).contains($0.rowID)
        }
    }

    private func finish(_ run: StoryRun) {
        guard let index = moments.firstIndex(where: { $0.id == run.momentID }) else { return }
        moments[index].playCount += 1
        moments[index].lastPlayedAt = Date()
        moments[index].lastOutcome = run.outcome ?? moments[index].lastOutcome
        guard !isSampleWorld else { return }
        do {
            try store?.save(moments[index])
            try store?.save(run)
        } catch {
            lastError = "Couldn't save the story: \(error)"
        }
    }

    public func useOnDeviceModel() {
        updateSettings { $0.storyModel = .onDevice }
    }

    /// Gives a moment a real title (detected moments start with placeholders).
    public func rename(_ momentID: String, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = moments.firstIndex(where: { $0.id == momentID }) else { return }
        moments[index].title = trimmed
        moments[index].titleIsProvisional = false
        let moment = moments[index]
        persist { try $0.save(moment) }
    }

    // MARK: Notes

    public func pinNote(_ body: String, to subjects: [ContextNote.Subject]) {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !subjects.isEmpty else { return }
        let new = subjects.map { ContextNote(subject: $0, body: text) }
        notes += new
        persist { try $0.save(new) }
    }

    public func deleteNote(_ note: ContextNote) {
        notes.removeAll { $0.id == note.id }
        persist { try $0.delete(ContextNote.self, id: note.id) }
    }

    /// Markdown of every note, grouped by who or what it's about.
    public func notesExport() -> String {
        var lines = ["# rerun — context notes", "", "_Exported \(Date().formatted(date: .long, time: .shortened))._", ""]
        for person in people {
            let theirs = notes(aboutPerson: person.id)
            guard !theirs.isEmpty else { continue }
            lines.append("## \(person.captionName)")
            for note in theirs {
                if case .moment(let id) = note.subject, let moment = moment(id) {
                    lines.append("- **\(moment.title):** \(note.body)")
                } else {
                    lines.append("- \(note.body)")
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Settings

    public func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&settings)
        persist(evenInSampleWorld: true) { store in try store.save(self.settings) }
    }

    public func setIncluded(_ personID: String, _ included: Bool) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        people[index].included = included
        if personFilter == personID && !included { personFilter = nil }
        let person = people[index]
        persist { try $0.save(person) }
    }

    /// Size of rerun's own database on disk ("1.2 GB, local").
    public var storageLabel: String {
        guard let url = try? RecordStore.defaultURL(), store != nil else { return "nothing stored" }
        let directory = url.deletingLastPathComponent()
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let bytes = files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file) + ", local"
    }

    /// Deletes everything rerun made. Messages itself is never touched.
    public func eraseWorld() {
        if let store {
            persist(evenInSampleWorld: true) { _ in
                try store.deleteAll(Moment.self)
                try store.deleteAll(Person.self)
                try store.deleteAll(VoiceProfile.self)
                try store.deleteAll(ContextNote.self)
                try store.deleteAll(StoryRun.self)
                try store.deleteAll(WorldMap.self)
                try store.deleteAll(AppSettings.self)
            }
        }
        stopPlaying()
        openMomentID = nil
        storylinePersonID = nil
        notesPersonID = nil
        personFilter = nil
        screen = .map
        reload()
        onboarding = store == nil ? nil : .welcome
    }

    /// Writes to the store. Edits to the sample world stay in memory, except
    /// settings, which are yours either way.
    private func persist(evenInSampleWorld: Bool = false, _ write: (RecordStore) throws -> Void) {
        guard let store, evenInSampleWorld || !isSampleWorld else { return }
        do {
            try write(store)
        } catch {
            lastError = "Couldn't save: \(error)"
        }
    }

    // MARK: Onboarding & scanning

    public var messagesAccess: MessagesLibrary.Access { MessagesLibrary.access() }

    public func skipOnboarding() {
        updateSettings { $0.hasCompletedOnboarding = true }
        onboarding = nil
    }

    /// "Allow access to Messages" / "check again" / "scan again".
    public func requestMessagesAccess() {
        switch messagesAccess {
        case .readable:
            Task { await survey() }
        case .needsFullDiskAccess:
            onboarding = .locked
        case .missing:
            onboarding = .noConversations
        }
    }

    public func openFullDiskAccessSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
    }

    private func survey() async {
        guard let store else { return }
        let names = SystemContactNames()
        await names.load()
        let result = await Task.detached(priority: .userInitiated) {
            Result { try WorldBuilder(store: store, names: names).survey() }
        }.value
        switch result {
        case .success(let people):
            candidates = people
            onboarding = .choosePeople
        case .failure(WorldBuildError.noConversations):
            onboarding = .noConversations
        case .failure(let error):
            lastError = "Couldn't read Messages: \(error)"
        }
    }

    public func setCandidate(_ id: String, included: Bool) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].included = included
    }

    /// Builds the world from the chosen candidates (or rescans with
    /// existing choices when there are none). Shows the building screen.
    public func buildWorld() async {
        guard let store, !isBuilding else { return }
        isBuilding = true
        let chosen = candidates.isEmpty ? nil : candidates
        onboarding = .building
        buildProgress = WorldBuildProgress(phase: .copying, fraction: 0)
        requestNotificationPermission()
        // The builder keeps whatever settings are stored (your name, topics, models).
        persist(evenInSampleWorld: true) { store in try store.save(self.settings) }

        let names = SystemContactNames()
        await names.load()
        let result = await Task.detached(priority: .userInitiated) { [weak self] () -> Result<WorldMap, Error> in
            Result {
                try WorldBuilder(store: store, names: names).build(people: chosen) { progress in
                    Task { @MainActor in
                        // Updates can land after the build has finished; drop those.
                        if self?.isBuilding == true { self?.buildProgress = progress }
                    }
                }
            }
        }.value

        isBuilding = false
        buildProgress = nil
        candidates = []
        switch result {
        case .success:
            reload()
            onboarding = nil
            screen = .map
            notifyWorldReady()
        case .failure(WorldBuildError.noConversations):
            onboarding = .noConversations
        case .failure(let error):
            onboarding = nil
            lastError = "Couldn't build your world: \(error)"
        }
    }

    /// Settings → Rescan Messages.
    public func rescan() {
        guard messagesAccess == .readable else {
            requestMessagesAccess()
            return
        }
        candidates = []
        Task { await buildWorld() }
    }

    // MARK: "we'll ping you"

    /// Notifications need a real app bundle; `swift run` builds don't have one.
    private var canNotify: Bool { Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app" }

    private func requestNotificationPermission() {
        guard canNotify else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notifyWorldReady() {
        guard canNotify, !NSApplication.shared.isActive else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your world is ready"
        content.body = "\(map.momentCount) moments, \(map.yearsSpanned()) years. Come play."
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "world-ready", content: content, trigger: nil))
    }
}
