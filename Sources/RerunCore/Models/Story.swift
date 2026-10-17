import Foundation

/// A simulated text inside the in-app iMessage mockup. Never sent anywhere.
public struct SimulatedMessage: Codable, Hashable, Sendable {
    /// Person id, or nil when the player sent it.
    public var senderID: String?
    public var text: String

    public init(senderID: String?, text: String) {
        self.senderID = senderID
        self.text = text
    }

    public var isFromPlayer: Bool { senderID == nil }
}

public struct StoryChoice: Codable, Hashable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
    }

    /// What lands in the phone when you pick it: quoted choices are texts you
    /// send ("“we're getting the 9:15”"); unquoted ones are actions.
    public var sentText: String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        for (open, close) in [("“", "”"), ("\"", "\"")] where trimmed.hasPrefix(open) && trimmed.hasSuffix(close) && trimmed.count > 2 {
            return String(trimmed.dropFirst().dropLast())
        }
        return nil
    }
}

/// One generated turn: how the last pick landed, the new scene, the texts
/// that arrive, and what you can say back.
public struct StoryBeat: Codable, Hashable, Sendable {
    public var chapter: Int
    public var chapterTitle: String?
    /// Replies to the player's previous pick, shown before the new scene.
    public var reactions: [SimulatedMessage]
    public var narration: String
    public var aside: String?
    /// The in-story clock ("6:52").
    public var clock: String?
    public var messages: [SimulatedMessage]
    public var choices: [StoryChoice]
    public var endsChapter: Bool
    public var endsStory: Bool
    /// How it ended, past tense ("you caught the 9:15"). Only on the last beat.
    public var outcome: String?
    /// The model's read on what the next scene is; routes the next turn.
    public var nextSceneTag: MomentTag?
    public var pickedChoice: Int?
    /// Which provider/model wrote this beat.
    public var route: ModelRoute?

    public init(
        chapter: Int,
        chapterTitle: String? = nil,
        reactions: [SimulatedMessage] = [],
        narration: String,
        aside: String? = nil,
        clock: String? = nil,
        messages: [SimulatedMessage],
        choices: [StoryChoice],
        endsChapter: Bool = false,
        endsStory: Bool = false,
        outcome: String? = nil,
        nextSceneTag: MomentTag? = nil,
        pickedChoice: Int? = nil,
        route: ModelRoute? = nil
    ) {
        self.chapter = chapter
        self.chapterTitle = chapterTitle
        self.reactions = reactions
        self.narration = narration
        self.aside = aside
        self.clock = clock
        self.messages = messages
        self.choices = choices
        self.endsChapter = endsChapter
        self.endsStory = endsStory
        self.outcome = outcome
        self.nextSceneTag = nextSceneTag
        self.pickedChoice = pickedChoice
        self.route = route
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chapter = try c.decode(Int.self, forKey: .chapter)
        chapterTitle = try c.decodeIfPresent(String.self, forKey: .chapterTitle)
        reactions = try c.decode(.reactions, default: [])
        narration = try c.decode(.narration, default: "")
        aside = try c.decodeIfPresent(String.self, forKey: .aside)
        clock = try c.decodeIfPresent(String.self, forKey: .clock)
        messages = try c.decode(.messages, default: [])
        choices = try c.decode(.choices, default: [])
        endsChapter = try c.decode(.endsChapter, default: false)
        endsStory = try c.decode(.endsStory, default: false)
        outcome = try c.decodeIfPresent(String.self, forKey: .outcome)
        nextSceneTag = try c.decodeIfPresent(MomentTag.self, forKey: .nextSceneTag)
        pickedChoice = try c.decodeIfPresent(Int.self, forKey: .pickedChoice)
        route = try c.decodeIfPresent(ModelRoute.self, forKey: .route)
    }

    /// The player's text for the picked choice, if it was a text.
    public var sentMessage: SimulatedMessage? {
        guard let pickedChoice, choices.indices.contains(pickedChoice),
              let text = choices[pickedChoice].sentText else { return nil }
        return SimulatedMessage(senderID: nil, text: text)
    }
}

/// One playthrough of a moment.
public struct StoryRun: StoredRecord, Hashable, Sendable {
    public static let table = "story_runs"

    public var id: String
    public var momentID: String
    public var startedAt: Date
    public var chapterCount: Int
    public var beats: [StoryBeat]
    public var finishedAt: Date?

    public init(id: String = UUID().uuidString, momentID: String, startedAt: Date = Date(), chapterCount: Int = 4) {
        self.id = id
        self.momentID = momentID
        self.startedAt = startedAt
        self.chapterCount = chapterCount
        self.beats = []
    }

    /// The chapter the next beat belongs to.
    public var currentChapter: Int {
        guard let last = beats.last else { return 1 }
        return last.endsChapter ? last.chapter + 1 : last.chapter
    }

    public var isFinished: Bool { beats.last?.endsStory == true }

    public var outcome: String? { beats.last(where: { $0.outcome != nil })?.outcome }

    /// The scene tag the next turn should be routed by.
    public func sceneTag(default tag: MomentTag) -> MomentTag {
        beats.last?.nextSceneTag ?? tag
    }

    /// Everything that's shown in the phone so far, in order.
    public var transcript: [SimulatedMessage] {
        beats.flatMap { beat in beat.reactions + beat.messages + (beat.sentMessage.map { [$0] } ?? []) }
    }
}
