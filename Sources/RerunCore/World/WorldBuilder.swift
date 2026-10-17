import Foundation

public struct WorldBuildProgress: Sendable {
    public enum Phase: String, Sendable {
        case copying = "making a private copy of Messages"
        case reading = "reading conversations"
        case listening = "learning how everyone texts"
        case findingMoments = "finding the moments"
        case drawing = "drawing your world"
    }

    public var phase: Phase
    public var fraction: Double
    public var detail: String?

    public init(phase: Phase, fraction: Double, detail: String? = nil) {
        self.phase = phase
        self.fraction = fraction
        self.detail = detail
    }
}

/// Builds (or rebuilds) the world from Messages: people, voice profiles,
/// moments and the map. Reads a private copy of chat.db; writes only to
/// rerun's own store. Excluded people are skipped before their texts are read.
public struct WorldBuilder {
    public var maxPeople = 12
    /// Threads smaller than this aren't worth a place in the world.
    public var minMessagesPerPerson = 50

    let store: RecordStore
    let names: ContactNameResolving
    let source: URL

    public init(store: RecordStore, names: ContactNameResolving = NoContactNames(), source: URL = MessagesLibrary.defaultURL) {
        self.store = store
        self.names = names
        self.source = source
    }

    public func build(progress: (WorldBuildProgress) -> Void = { _ in }) throws -> WorldMap {
        progress(.init(phase: .copying, fraction: 0))
        let snapshot = try MessagesSnapshot(source: source)
        let reader = ChatDatabaseReader(snapshot: snapshot)

        progress(.init(phase: .reading, fraction: 0.1))
        let existingPeople = try store.all(Person.self)
        let existingMoments = try store.all(Moment.self)
        let people = mergePeople(try reader.chats(), existing: existingPeople)

        var voices: [VoiceProfile] = []
        var moments: [Moment] = []
        var earliest: Date?
        let profiler = VoiceProfiler()
        let detector = MomentDetector()

        for (index, person) in people.enumerated() where person.included {
            let fraction = 0.15 + 0.75 * Double(index) / Double(max(1, people.count))
            progress(.init(phase: .listening, fraction: fraction, detail: person.displayName))
            let threads = try person.chatIDs.map { chatID in (chatID, try reader.messages(inChat: chatID)) }
            let everything = threads.flatMap(\.1).sorted { $0.date < $1.date }
            if let first = everything.first?.date, first < (earliest ?? .distantFuture) { earliest = first }
            voices.append(profiler.profile(id: person.id, thread: everything) { !$0.isFromMe })

            progress(.init(phase: .findingMoments, fraction: fraction, detail: person.displayName))
            for (chatID, messages) in threads {
                for candidate in detector.detect(in: messages) {
                    let source = MomentSource(chatID: chatID, firstMessageRowID: candidate.firstRowID, lastMessageRowID: candidate.lastRowID)
                    if let previous = existingMoments.first(where: { $0.source == source }) {
                        moments.append(previous)
                        continue
                    }
                    moments.append(Moment(
                        title: MomentDetector.provisionalTitle(for: candidate.tag, date: candidate.start, with: person.displayName),
                        titleIsProvisional: true,
                        date: candidate.start,
                        endDate: candidate.end,
                        primaryPersonID: person.id,
                        tag: candidate.tag,
                        evidence: EvidenceKind.forTag(candidate.tag).map { Evidence($0) },
                        messageCount: candidate.messageCount,
                        source: source
                    ))
                }
            }
        }

        progress(.init(phase: .drawing, fraction: 0.95))
        let map = WorldLayout().layout(people: people, moments: moments, momentCount: moments.count, since: earliest)
        try store.deleteAll(Moment.self)
        try store.deleteAll(Person.self)
        try store.save(people)
        try store.save(moments)
        try store.save(voices)
        try store.save(map)
        var settings = try store.get(AppSettings.self, id: AppSettings.singletonID) ?? AppSettings()
        settings.lastScanAt = Date()
        try store.save(settings)
        progress(.init(phase: .drawing, fraction: 1))
        return map
    }

    /// One person per contact (their iMessage and SMS threads merged), one per
    /// group chat; the biggest `maxPeople`, keeping ids and choices from earlier scans.
    func mergePeople(_ chats: [ChatSummary], existing: [Person]) -> [Person] {
        var direct: [String: (handles: Set<String>, chats: [ChatSummary])] = [:]
        var groups: [ChatSummary] = []
        for chat in chats where chat.messageCount > 0 {
            if chat.isGroup {
                groups.append(chat)
            } else if let handle = chat.participantHandles.first ?? Optional(chat.identifier), !handle.isEmpty {
                let key = HandleFormat.phoneKey(handle) ?? handle.lowercased()
                direct[key, default: ([], [])].handles.insert(handle)
                direct[key, default: ([], [])].chats.append(chat)
            }
        }

        var people: [Person] = direct.values.map { entry in
            let handles = entry.handles.sorted()
            let name = handles.lazy.compactMap(names.name(forHandle:)).first ?? HandleFormat.fallbackName(handles[0])
            let threads = entry.chats.sorted { $0.messageCount > $1.messageCount }
            return Person(displayName: name, handles: handles, chatIDs: threads.map(\.id), color: .coral, messageCount: threads.reduce(0) { $0 + $1.messageCount })
        }
        people += groups.map { chat in
            let firstNames = chat.participantHandles.prefix(3).map { (names.name(forHandle: $0) ?? HandleFormat.fallbackName($0)).split(separator: " ").first.map(String.init) ?? $0 }
            let name = chat.displayName ?? firstNames.joined(separator: ", ")
            return Person(displayName: name, handles: chat.participantHandles, chatIDs: [chat.id], isGroup: true, color: .coral, messageCount: chat.messageCount)
        }

        let ranked = people
            .filter { $0.messageCount >= minMessagesPerPerson }
            .sorted { $0.messageCount > $1.messageCount }
            .prefix(maxPeople)

        return ranked.enumerated().map { rank, person in
            var person = person
            person.color = .forRank(rank)
            if let previous = existing.first(where: { !Set($0.chatIDs).isDisjoint(with: person.chatIDs) }) {
                person.id = previous.id
                person.included = previous.included
                person.color = previous.color
            }
            return person
        }
    }
}
