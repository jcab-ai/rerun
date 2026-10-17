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

public enum WorldBuildError: Error, Equatable {
    /// chat.db opened, but there's nobody to build a world from.
    case noConversations
}

/// Builds (or rebuilds) the world from Messages: people, voice profiles,
/// moments and the map. Reads a private copy of chat.db; writes only to
/// rerun's own store. Excluded people are skipped before their texts are read.
public struct WorldBuilder {
    public var maxPeople = 12
    /// How many of the biggest threads start out included.
    public var includedByDefault = 5
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

    /// The people rerun could build a world from, biggest threads first,
    /// without reading any message text. Keeps ids and choices from earlier scans.
    public func survey() throws -> [Person] {
        let snapshot = try MessagesSnapshot(source: source)
        let people = mergePeople(try ChatDatabaseReader(snapshot: snapshot).chats(), existing: try store.all(Person.self))
        guard !people.isEmpty else { throw WorldBuildError.noConversations }
        return people
    }

    /// Reads the included people's threads and replaces the world.
    /// - Parameter people: who to build from (e.g. after "Who's in your world?");
    ///   nil surveys again and keeps earlier include/exclude choices.
    @discardableResult
    public func build(people chosen: [Person]? = nil, progress: (WorldBuildProgress) -> Void = { _ in }) throws -> WorldMap {
        progress(.init(phase: .copying, fraction: 0))
        let snapshot = try MessagesSnapshot(source: source)
        let reader = ChatDatabaseReader(snapshot: snapshot)

        progress(.init(phase: .reading, fraction: 0.08))
        let existingMoments = try store.all(Moment.self)
        var people = try chosen ?? mergePeople(reader.chats(), existing: store.all(Person.self))
        guard !people.isEmpty else { throw WorldBuildError.noConversations }

        var voices: [VoiceProfile] = []
        var moments: [Moment] = []
        var earliest: Date?
        let profiler = VoiceProfiler()
        let detector = MomentDetector()
        let included = people.indices.filter { people[$0].included }

        for (step, index) in included.enumerated() {
            let person = people[index]
            let fraction = 0.12 + 0.8 * Double(step) / Double(max(1, included.count))
            progress(.init(phase: .listening, fraction: fraction, detail: "reading \(person.messageCount.formatted()) messages with \(person.displayName)"))
            let threads = try person.chatIDs.map { chatID in (chatID, try reader.messages(inChat: chatID)) }
            let everything = threads.flatMap(\.1).sorted { $0.date < $1.date }
            if let first = everything.first?.date {
                people[index].since = first
                if first < (earliest ?? .distantFuture) { earliest = first }
            }
            let voice = profiler.profile(id: person.id, thread: everything) { !$0.isFromMe }
            voices.append(voice)
            if let trait = voice.learnedLines.first {
                progress(.init(phase: .listening, fraction: fraction, detail: "learning that \(person.displayName) \(trait.prefix(1).lowercased() + trait.dropFirst())"))
            }

            progress(.init(phase: .findingMoments, fraction: fraction, detail: "finding the moments with \(person.displayName)"))
            var found = 0
            for (chatID, messages) in threads {
                for candidate in detector.detect(in: messages) {
                    found += 1
                    let source = MomentSource(chatID: chatID, firstMessageRowID: candidate.firstRowID, lastMessageRowID: candidate.lastRowID)
                    if let previous = existingMoments.first(where: { $0.source == source }) {
                        moments.append(previous)
                        continue
                    }
                    let slice = Array(messages[candidate.range])
                    moments.append(Moment(
                        title: MomentDetector.provisionalTitle(for: candidate.tag, date: candidate.start, with: person.displayName),
                        titleIsProvisional: true,
                        date: candidate.start,
                        endDate: candidate.end,
                        primaryPersonID: person.id,
                        tag: candidate.tag,
                        evidence: EvidenceKind.forTag(candidate.tag).map { Evidence($0) },
                        quote: MomentDetector.quote(in: slice),
                        messageCount: candidate.messageCount,
                        chapterCount: 3,
                        source: source
                    ))
                }
            }
            people[index].momentCount = found
        }

        progress(.init(phase: .drawing, fraction: 0.95, detail: "stitching \(moments.count) moments together"))
        let map = WorldLayout().layout(people: people, moments: moments, momentCount: moments.count, since: earliest)
        try store.deleteAll(Moment.self)
        try store.deleteAll(Person.self)
        try store.deleteAll(VoiceProfile.self)
        try store.save(people)
        try store.save(moments)
        try store.save(voices)
        try store.save(map)
        var settings = try store.get(AppSettings.self, id: AppSettings.singletonID) ?? AppSettings()
        settings.lastScanAt = Date()
        settings.hasCompletedOnboarding = true
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

        func firstName(_ handle: String) -> String {
            let name = names.name(forHandle: handle) ?? HandleFormat.fallbackName(handle)
            return name.split(separator: " ").first.map(String.init) ?? name
        }

        var people: [Person] = direct.values.map { entry in
            let handles = entry.handles.sorted()
            let fullName = handles.lazy.compactMap(names.name(forHandle:)).first
            let threads = entry.chats.sorted { $0.messageCount > $1.messageCount }
            return Person(
                displayName: fullName.map { $0.split(separator: " ").first.map(String.init) ?? $0 } ?? HandleFormat.fallbackName(handles[0]),
                fullName: fullName,
                handles: handles,
                chatIDs: threads.map(\.id),
                color: .coral,
                messageCount: threads.reduce(0) { $0 + $1.messageCount }
            )
        }
        people += groups.map { chat in
            let members = chat.participantHandles.map(firstName)
            return Person(
                displayName: chat.displayName ?? members.prefix(3).joined(separator: ", "),
                relationship: "group chat · \(members.count + 1) people",
                handles: chat.participantHandles,
                chatIDs: [chat.id],
                isGroup: true,
                members: members,
                color: .coral,
                messageCount: chat.messageCount
            )
        }

        let ranked = people
            .filter { $0.messageCount >= minMessagesPerPerson }
            .sorted { $0.messageCount > $1.messageCount }
            .prefix(maxPeople)

        return ranked.enumerated().map { rank, person in
            var person = person
            person.color = .forRank(rank)
            person.included = rank < includedByDefault
            if let previous = existing.first(where: { !Set($0.chatIDs).isDisjoint(with: person.chatIDs) }) {
                person.id = previous.id
                person.included = previous.included
                person.color = previous.color
                person.relationship = previous.relationship ?? person.relationship
                person.momentCount = previous.momentCount
                person.since = previous.since
            }
            return person
        }
    }
}
