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
}

/// One generated turn: scene-setting, the texts that arrive, what you can say back.
public struct StoryBeat: Codable, Hashable, Sendable {
    public var chapter: Int
    public var chapterTitle: String?
    public var narration: String
    public var aside: String?
    public var messages: [SimulatedMessage]
    public var choices: [StoryChoice]
    public var endsChapter: Bool
    /// The model's read on what the next scene is; routes the next turn.
    public var nextSceneTag: MomentTag?
    public var pickedChoice: Int?
    /// Which provider/model wrote this beat.
    public var route: ModelRoute?

    public init(
        chapter: Int,
        chapterTitle: String? = nil,
        narration: String,
        aside: String? = nil,
        messages: [SimulatedMessage],
        choices: [StoryChoice],
        endsChapter: Bool = false,
        nextSceneTag: MomentTag? = nil,
        pickedChoice: Int? = nil,
        route: ModelRoute? = nil
    ) {
        self.chapter = chapter
        self.chapterTitle = chapterTitle
        self.narration = narration
        self.aside = aside
        self.messages = messages
        self.choices = choices
        self.endsChapter = endsChapter
        self.nextSceneTag = nextSceneTag
        self.pickedChoice = pickedChoice
        self.route = route
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

    public var currentChapter: Int {
        guard let last = beats.last else { return 1 }
        return last.endsChapter ? last.chapter + 1 : last.chapter
    }

    /// The scene tag the next turn should be routed by.
    public func sceneTag(default tag: MomentTag) -> MomentTag {
        beats.last?.nextSceneTag ?? tag
    }
}
